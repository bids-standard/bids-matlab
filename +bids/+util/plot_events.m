function plot_events(varargin)
  %
  % USAGE::
  %
  %   plot_events(events_files, 'include', include, ...
  %                             'trial_type_col', 'trial_type', ...
  %                             'model_file', path_to_model)
  %
  % :param events_files: BIDS events TSV files.
  % :type  events_files: path or cellstr of paths
  %
  % :param include: Optional. Restrict conditions to plot.
  % :type  include: char or cellstr
  %
  % :param trial_type_col:  Optional. Defines the column where trial types are
  %                        listed. Defaults to 'trial_type'
  % :type  trial_type_col: char or cellstr
  %
  % :param model_file:  Optional. Bids stats model file to apply to events.tsv
  %                     before plotting
  % :type  model_file: fullpath
  %
  % Example::
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
  %   include = {'Reapp_Neg_Cue', 'Look_Neg_Cue', 'Look_Neutral_Cue'};
  %   bids.util.plot_events(events_files, 'include', include);
  %
  %

  % (C) Copyright 2020 Remi Gau

  args = inputParser();

  file_or_cellstring = @(x) (iscellstr(x) || exist(x, 'file'));
  empty_or_file = @(x) (isempty(x) || exist(x, 'file'));
  char_or_cellstring = @(x) (ischar(x) || iscellstr(x));

  addRequired(args, 'events_files', file_or_cellstring);
  addParameter(args, 'include', {}, char_or_cellstring);
  addParameter(args, 'trial_type_col', 'trial_type', @ischar);
  addParameter(args, 'model_file', '', empty_or_file);

  parse(args, varargin{:});

  events_files = args.Results.events_files;
  include = args.Results.include;
  trial_type_col = args.Results.trial_type_col;
  model_file = args.Results.model_file;

  if ischar(include)
    include = {include};
  end

  if ischar(events_files)
    events_files = {events_files};
  end

  bm = '';
  if ~isempty(model_file)
    bm = bids.Model('file', model_file, 'verbose', true);
  end

  for i = 1:numel(events_files)
    plot_this_file(events_files{i}, include, trial_type_col, bm);
  end

end

function plot_this_file(this_file, include, trial_type_col, bm)

  % From colorbrewer
  % http://colorbrewer2.org/
  COLORS = [166, 206, 227
            31, 120, 180
            178, 223, 138
            51, 160, 44
            251, 154, 153
            227, 26, 28
            253, 191, 111
            255, 127, 0
            202, 178, 214
            106, 61, 154
            255, 255, 153
            177, 89, 40];

  tsv_content = bids.util.tsvread(this_file);

  matrix = {};
  data = tsv_content;
  if ~isempty(bm)
    [~, root_node_name] = bm.get_root_node();
    transformers = bm.get_transformations('Name', root_node_name);
    matrix = bm.get_design_matrix('Name', root_node_name);
    data = bids.transformers(transformers.Instructions, tsv_content);
  end

  bids_file = bids.File(this_file);

  data = get_events_data(data, trial_type_col, include, matrix);

  [nb_col, nb_rows, subplot_grid] = return_figure_spec(tsv_content, data);

  % ensure we have enough colors for all conditions
  COLORS = repmat(COLORS, ceil(nb_rows / size(COLORS, 1)), 1);

  fig_name = strrep(bids_file.filename, '_', ' ');
  fig_name = strrep(fig_name, 'events.tsv', ' ');
  figure('name', fig_name, ...
         'position', [50 50 2000 1000]);

  for iCdt = 1:nb_rows

    this_color = COLORS(iCdt, :) / 255;

    onset = data(iCdt).onset;

    duration =  data(iCdt).duration;

    %% Time course
    subplot(nb_rows, nb_col, subplot_grid{iCdt, 1});

    hold on;

    if all(duration == 0)

      stem(onset, ones(1, numel(onset)), 'linecolor', this_color);

    else

      for iStim = 1:numel(onset)

        rectangle('position', [onset(iStim) 0 duration(iStim) 1], ...
                  'FaceColor', this_color, ...
                  'EdgeColor', this_color);
      end

    end

    response_time = data(iCdt).response_time;
    plot_response_time(response_time, onset);

    ylabel(sprintf(strrep(data(iCdt).name, '_', '\n')));

    %% Duration distribution
    subplot(nb_rows, nb_col, subplot_grid{iCdt, 2});
    plot_histogram(diff(onset), this_color);

    %% Response time distribution
    has_response = ~isnan(response_time);
    if any(has_response)
      subplot(nb_rows, nb_col, subplot_grid{iCdt, 3});
      plot_histogram(response_time(has_response), this_color);
    end

  end

  %% Update axis
  xMin = floor(min(cat(1, data.onset))) - 1;
  xMax = ceil(max(cat(1, data.onset) + cat(1, data.duration)));
  xMax = xMax + 5;

  yMin = 0;
  yMax = 1.1;

  for iCdt = 1:nb_rows

    subplot(nb_rows, nb_col, subplot_grid{iCdt, 1});

    axis([xMin xMax yMin yMax]);

    % x tick in minutes
    set(gca, ...
        'xTick', 0:60:xMax, ...
        'xTickLabel', '', ...
        'TickDir', 'out');
  end

  subplot(nb_rows, nb_col, subplot_grid{1, 1});
  title(fig_name);

  subplot(nb_rows, nb_col, subplot_grid{end, 1});
  set(gca, ...
      'xTick', 0:60:xMax, ...
      'xTickLabel', 0:60:xMax, ...
      'TickDir', 'out');
  xlabel('seconds');

  subplot(nb_rows, nb_col, subplot_grid{1, 2});
  title('ISI distribution');

  subplot(nb_rows, nb_col, subplot_grid{end, 2});
  xlabel('seconds');

  if isfield(tsv_content, 'response_time')

    subplot(nb_rows, nb_col, subplot_grid{end, 3});
    xlabel('seconds');

    subplot(nb_rows, nb_col, subplot_grid{1, 3});
    title('response time distribution');

  end

end

function [nb_col, nb_rows, subplot_grid] = return_figure_spec(tsv_content, data)

  nb_rows = numel(data);

  nb_col = 8;
  subplot_col_1 = 1:(nb_col - 1);
  subplot_col_2 = nb_col;
  subplot_col_3 = nan;

  if isfield(tsv_content, 'response_time')
    nb_col = 9;
    subplot_col_1 = 1:(nb_col - 2);
    subplot_col_2 = nb_col - 1;
    subplot_col_3 = nb_col;
  end

  subplot_grid = {subplot_col_1, subplot_col_2, subplot_col_3};

  for iCdt = 2:nb_rows
    subplot_grid{iCdt, 1} = subplot_grid{iCdt - 1, 1} + +nb_col;
    subplot_grid{iCdt, 2} = subplot_grid{iCdt - 1, 2} + +nb_col;
    subplot_grid{iCdt, 3} = subplot_grid{iCdt - 1, 3} + +nb_col;
  end

end

function data = get_events_data(data, trial_type_col, include, matrix)

  % TODO deal with events.tsv with only onset and duration
  trial_type = data.(trial_type_col);
  trial_type_list = unique(trial_type);

  if isempty(matrix)
    for iCdt = 1:numel(trial_type_list)
      matrix{iCdt} = [trial_type_col '.' trial_type_list{iCdt}];
    end
  end

  tmp = struct('name', '', 'onset', [], 'duration', [], 'response_time', []);

  counter = 1;

  for i = 1:numel(matrix)

    if ~ischar(matrix{i})
      continue
    end

    tokens = strsplit(matrix{i}, '.');
    if numel(tokens) ~= 2
      continue
    end

    if ~isempty(include) && ~ismember(tokens{2}, include)
      continue
    end

    idx = strcmp(data.(tokens{1}), tokens{2});

    tmp(counter).name = tokens{2};
    tmp(counter).onset = data.onset(idx);
    tmp(counter).duration = data.duration(idx);
    tmp(counter).response_time = nan(size(tmp(counter).onset));
    if isfield(data, 'response_time')
      tmp(counter).response_time = data.response_time(idx);
    end

    counter = counter + 1;
  end

  data = tmp;

end

function plot_response_time(response_time, onset)
  response_time = onset + response_time;
  has_response = ~isnan(response_time);
  if any(has_response)
    stem(response_time(has_response), 0.5 * ones(1, sum(has_response)), 'k');
  end
end

function plot_histogram(values, this_color)
  hold on;

  hist(values, 20, 1);
  h = findobj(gca, 'Type', 'patch');
  set(h, 'FaceColor', this_color);
  set(h, 'EdgeColor', 'w');

  ax = axis;
  plot([0 0], [ax(3) ax(4)], 'k');
  plot([ax(1) ax(2)], [0 0], 'k');
end
