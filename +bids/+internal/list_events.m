function [data, headers, y_labels] = list_events(varargin)
  %
  % Returns summary of all events for a given task.
  %
  % USAGE::
  %
  %  [data, headers, y_labels] = bids.internal.list_events(BIDS, ...
  %                                                         modality, ...
  %                                                         task, ...
  %                                                         'filter', struct(), ...
  %                                                         'trial_type_col', 'trial_type')
  %
  % :param BIDS:       BIDS directory name or BIDS structure (from ``bids.layout``)
  % :type  BIDS:       structure or char
  %
  % :param modality:   name of the modality
  % :type  modality:   char
  %
  % :param task:       name of the task
  % :type  task:       char
  %
  % :param filter:     Optional. List of filters to choose what files to copy
  %                    (see bids.query). Default to ``struct()``.
  % :type  filter:     structure or cell
  %
  % :param trial_type_col:    Optional. Name of the column containing the trial type.
  %                           Defaults to ``'trial_type'``.
  % :type  trial_type_col:    char
  %
  % See also: bids.diagnostic, bids.internal.plot_diagnostic_table
  %

  % (C) Copyright 2022 Remi Gau

  is_dir_or_struct = @(x) (isstruct(x) || isdir(x));

  args = inputParser();
  addRequired(args, 'BIDS', is_dir_or_struct);
  addRequired(args, 'modality');
  addRequired(args, 'task');
  addParameter(args, 'filter', struct(), @isstruct);
  addParameter(args, 'trial_type_col', 'trial_type', @ischar);

  parse(args, varargin{:});

  BIDS = args.Results.BIDS;
  modality = args.Results.modality;
  task = args.Results.task;
  trial_type_col = args.Results.trial_type_col;
  filter = args.Results.filter;

  BIDS = bids.layout(BIDS);

  this_filter = filter;
  this_filter.task = task;
  this_filter.modality = modality;
  subjects = bids.query(BIDS, 'subjects', this_filter);

  y_labels = {};
  headers = {};
  data = [];

  if  isempty(subjects)
    return
  end

  trial_type_list = bids.internal.list_all_trial_types(BIDS, task, ...
                                                       'tolerant', true, 'verbose', true);

  if  isempty(trial_type_list)
    data = [];
    return
  end

  % get number of events file to initialize table
  this_filter = get_clean_filter(filter, subjects, modality, task);
  event_files = bids.query(BIDS, 'data', this_filter);
  data = zeros(numel(event_files), numel(trial_type_list));

  for i = 1:numel(trial_type_list)
    headers{i}.modality{1} = strrep(trial_type_list{i}, '_', ' ');
  end

  row = 1;
  for i_sub = 1:numel(subjects)

    this_filter = get_clean_filter(filter, subjects{i_sub}, modality, task);

    sessions = bids.query(BIDS, 'sessions', this_filter);
    if isempty(sessions)
      sessions = {''};
    end

    for i_sess = 1:numel(sessions)

      this_filter = get_clean_filter(filter, subjects{i_sub}, modality, task);
      this_filter.ses = sessions{i_sess};

      event_files = bids.query(BIDS, 'data', this_filter);

      for i_file = 1:size(event_files, 1)

        this_label = bids.internal.file_utils(event_files{i_file, 1}, 'basename');
        this_label = strrep(this_label, '_', ' ');
        this_label = strrep(this_label, ' events', '');
        y_labels{end + 1, 1} = this_label; %#ok<*AGROW>

        content = bids.util.tsvread(event_files{i_file, 1});

        if ~isfield(content, trial_type_col)
          row = row + 1;
          continue
        end

        trials = content.(trial_type_col);
        if ~iscell(trials) && all(isnumeric(trials))
          trials = cellstr(num2str(trials));
        end

        for i_trial_type = 1:numel(trial_type_list)
          tmp = ismember(trials, trial_type_list{i_trial_type});
          data(row, i_trial_type) = sum(tmp);
        end

        row = row + 1;

      end

    end

  end

end

function this_filter = get_clean_filter(filter, sub, modality, task)
  this_filter = filter;
  this_filter.sub = sub;
  this_filter.task = task;
  this_filter.modality = modality;
  this_filter.suffix = 'events';
  this_filter.extension = '.tsv';
end
