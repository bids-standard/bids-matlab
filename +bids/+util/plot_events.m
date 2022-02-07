function plot_events(varargin)
  %
  % USAGE::
  %
  %   plot_events(events_files)
  %
  % :param events_files: Path to a bids _events.tsv file.
  % :type events_files: string
  %
  % EXAMPLE::
  %
  %     data_dir = fullfile('bids-examples', 'ds001');
  %
  %     events_files = bids.query(data_dir, ...
  %                             'data', ...
  %                             'sub', '01', ...
  %                             'task', 'balloonanalogrisktask', ...
  %                             'suffix', 'events');
  %
  %     plotEvents(events_files{1});
  %
  % (C) Copyright 2020 Remi Gau

  args = inputParser();

  file_or_cellstring = @(x) (iscellstr(x) || exist(x, 'file'));
  char_or_cellstring = @(x) (ischar(x) || iscellstr(x));

  addRequired(args, 'events_files', file_or_cellstring);
  addParameter(args, 'filter', {}, char_or_cellstring);

  parse(args, varargin{:});

  events_files = args.Results.events_files;
  filter = args.Results.filter;

  if ischar(events_files)
    events_files = {events_files};
  end

  for i = 1:numel(events_files)
    plot_this_file(events_files{i});
  end

end

function plot_this_file(this_file)

  bids_file = bids.File(this_file);

  fig_name = strrep(bids_file.filename, '_', ' ');
  fig_name = strrep(fig_name, 'events.tsv', ' ');

  data = bids.util.tsvread(this_file);

  trial_type = data.trial_type;
  trial_type_list = unique(trial_type);

  xMin = floor(min(data.onset)) - 1;
  xMax = ceil(max(data.onset + data.duration));

  yMin = 0;
  yMax = 1;

  figure('name', fig_name, 'position', [50 50 1000 1000]);

  for iCdt = 1:numel(trial_type_list)

    idx = strcmp(trial_type, trial_type_list{iCdt});

    onsets = data.onset(idx);

    duration = data.duration(idx);

    if isfield(data, 'response_time')
      response_time = data.response_time;
    else
      response_time = nan(size(onsets));
    end

    subplot(numel(trial_type_list), 1, iCdt);

    hold on;

    if all(duration == 0)

      stem(onsets, ones(1, numel(onsets)), 'r');

    else

      for iStim = 1:numel(onsets)

        offset = onsets(iStim) + duration(iStim);
        xMax = max([xMax; offset]);

        rectangle('position', [onsets(iStim) 0 duration(iStim) 1], ...
                  'FaceColor', 'r');
      end

    end

    % add response time
    for iStim = 1:numel(onsets)
      if ~isnan(response_time(iStim))
        stem(onsets(iStim) + response_time(iStim), 0.5, 'k');
      end
    end

    ylabel(sprintf(strrep(trial_type_list{iCdt}, '_', '\n')));

  end

  xMax = xMax + 5;

  for iCdt = 1:numel(trial_type_list)

    subplot(numel(trial_type_list), 1, iCdt);

    axis([xMin xMax yMin yMax]);

    xlabel('seconds');

    subplot(numel(trial_type_list), 1, 1);

  end

  title(fig_name);

end
