function plot_events(varargin)
  %
  % USAGE::
  %
  %   plot_events(events_files, 'filter', filter)
  %
  % :param events_files: BIDS events TSV files.
  % :type events_files: path or cellstr of paths
  %
  % :param filter: Restrict conditions to plot.
  % :type filter: string or cellstr
  %
  % EXAMPLE::
  %
  %   data_dir = fullfile(get_test_data_dir(), 'ds108');
  %
  %   BIDS = bids.layout(data_dir);
  %
  %   events_files = bids.query(BIDS, ...
  %                             'data', ...
  %                             'sub', '01', ...
  %                             'run', '01', ...
  %                             'suffix', 'events');
  %
  %   filter = {'Reapp_Neg_Cue', 'Look_Neg_Cue', 'Look_Neutral_Cue'};
  %   bids.util.plot_events(events_files, 'filter', filter);
  %
  %

  % (C) Copyright 2020 Remi Gau

  % TODO add reponse_time column

  args = inputParser();

  file_or_cellstring = @(x) (iscellstr(x) || exist(x, 'file'));
  char_or_cellstring = @(x) (ischar(x) || iscellstr(x));

  addRequired(args, 'events_files', file_or_cellstring);
  addParameter(args, 'filter', {}, char_or_cellstring);

  parse(args, varargin{:});

  events_files = args.Results.events_files;
  filter = args.Results.filter;

  if ischar(filter)
    filter = {filter};
  end

  if ischar(events_files)
    events_files = {events_files};
  end

  for i = 1:numel(events_files)
    plot_this_file(events_files{i}, filter);
  end

end

function plot_this_file(this_file, filter)

  bids_file = bids.File(this_file);

  fig_name = strrep(bids_file.filename, '_', ' ');
  fig_name = strrep(fig_name, 'events.tsv', ' ');

  data = bids.util.tsvread(this_file);

  trial_type = data.trial_type;
  if ~isempty(filter)
    trial_type_list = filter;
  else
    trial_type_list = unique(trial_type);
  end

  xMin = floor(min(data.onset)) - 1;
  xMax = ceil(max(data.onset + data.duration));

  yMin = 0;
  yMax = 1;

  nb_col = 8;
  nb_rows = numel(trial_type_list);

  figure('name', fig_name, ...
         'position', [50 50 2000 1000]);

  subplot_col_1 = 1:(nb_col - 1);
  subplot_col_2 = nb_col;

  for iCdt = 1:numel(trial_type_list)

    idx = strcmp(trial_type, trial_type_list{iCdt});

    onsets = data.onset(idx);

    durations = data.duration(idx);

    if isfield(data, 'response_time')
      response_times = data.response_time(idx);
    else
      response_times = nan(size(onsets));
    end

    %% Time course
    subplot(nb_rows, nb_col, subplot_col_1);

    hold on;

    if all(durations == 0)

      stem(onsets, ones(1, numel(onsets)), 'r');

    else

      for iStim = 1:numel(onsets)

        offsets = onsets(iStim) + durations(iStim);
        xMax = max([xMax; offsets]);

        rectangle('position', [onsets(iStim) 0 durations(iStim) 1], ...
                  'FaceColor', 'r');
      end

    end

    % add response time
    response_times = onsets + response_times;
    has_response = ~isnan(response_times);
    if any(has_response)
      stem(response_times(has_response), 0.5 * ones(1, sum(has_response)), 'k');
    end

    ylabel(sprintf(strrep(trial_type_list{iCdt}, '_', '\n')));

    %% Duration distribution
    subplot(nb_rows, nb_col, subplot_col_2);

    hold on;

    hist(diff(onsets));

    ax = axis;
    plot([0 0], [ax(3) ax(4)], 'k');
    plot([ax(1) ax(2)], [0 0], 'k');

    %% Increment
    subplot_col_1 = subplot_col_1 + nb_col;
    subplot_col_2 = subplot_col_2 + nb_col;

  end

  %% Update axis
  xMax = xMax + 5;

  subplot_col_1 = 1:(nb_col - 1);
  for iCdt = 1:numel(trial_type_list)

    subplot(nb_rows, nb_col, subplot_col_1);

    axis([xMin xMax yMin yMax]);

    % x tick in minutes
    set(gca, ...
        'xTick', 0:60:xMax, ...
        'xTickLabel', '', ...
        'TickDir', 'out');

    subplot_col_1 = subplot_col_1 + nb_col;

  end

  subplot(nb_rows, nb_col, 1:(nb_col - 1));
  title(fig_name);

  subplot(nb_rows, nb_col, [1:(nb_col - 1)] + (nb_col * (nb_rows - 1))); %#ok<NBRAK>
  set(gca, ...
      'xTick', 0:60:xMax, ...
      'xTickLabel', 0:60:xMax, ...
      'TickDir', 'out');
  xlabel('seconds');

  subplot(nb_rows, nb_col, nb_col);
  title('ISI distribution');

  subplot(nb_rows, nb_col, nb_rows * nb_col);
  xlabel('seconds');

end
