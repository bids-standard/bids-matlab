function trial_type_list = list_all_trial_types(varargin)
  %
  % List all the trial_types in all the events.tsv files for a task.
  %
  % USAGE::
  %
  %   trial_type_list = bids.internal.list_all_trial_types(BIDS, , ...
  %                                                        task, ...
  %                                                        'trial_type_col', 'trial_type', ...
  %                                                        'tolerant', true, ...
  %                                                        'verbose', false)
  %
  % :param BIDS:              BIDS directory name or BIDS structure (from ``bids.layout``)
  % :type  BIDS:              structure or char
  %
  % :param task:              name of the task
  % :type  task:              char
  %
  % :param trial_type_col:    Optional. Name of the column containing the trial type.
  %                           Defaults to ``'trial_type'``.
  % :type  trial_type_col:    char
  %
  % :param tolerant:          Optional. Default to ``true``.
  % :type  tolerant:          logical
  %
  % :param verbose:          Optional. Default to ``false``.
  % :type  verbose:          logical
  %
  %

  % (C) Copyright 2022 Remi Gau

  default_tolerant = true;
  default_verbose = false;

  is_dir_or_struct = @(x) (isstruct(x) || isfolder(x));

  args = inputParser();
  addRequired(args, 'BIDS', is_dir_or_struct);
  addRequired(args, 'task');
  addParameter(args, 'modality', '.*', @ischar);
  addParameter(args, 'trial_type_col', 'trial_type', @ischar);
  addParameter(args, 'tolerant', default_tolerant);
  addParameter(args, 'verbose', default_verbose);

  parse(args, varargin{:});

  BIDS = args.Results.BIDS;
  task = args.Results.task;
  modality = args.Results.modality;
  trial_type_col = args.Results.trial_type_col;
  tolerant = args.Results.tolerant;
  verbose = args.Results.verbose;

  trial_type_list = {};

  BIDS = bids.layout(BIDS, 'index_dependencies', false);

  event_files = bids.query(BIDS, 'data', ...
                           'suffix', 'events', ...
                           'extension', '.tsv', ...
                           'task', task);

  if isempty(event_files)
    msg = sprintf('No events.tsv files for tasks:%s', ...
                  bids.internal.create_unordered_list(task));
    bids.internal.error_handling(mfilename(), 'noEventsFile', ...
                                 msg, ...
                                 tolerant, ...
                                 verbose);
    return
  end

  no_trial_type_column = true;
  for i = 1:size(event_files, 1)
    try
      content = bids.util.tsvread(event_files{i, 1});
    catch ME
      if bids.internal.starts_with(ME.message, 'Invalid DSV file')
        continue
      else
        rethrow ME;
      end

    end
    if isfield(content, trial_type_col)
      trial_type = content.(trial_type_col);
      no_trial_type_column = false;
      if ~iscell(trial_type) && all(isnumeric(trial_type))
        trial_type = cellstr(num2str(trial_type));
      end
      trial_type_list = cat(1, trial_type_list, trial_type);
      trial_type_list = unique(trial_type_list);
    end
  end

  if no_trial_type_column
    msg = sprintf('No "%s" column found in files:%s', ...
                  trial_type_col, ...
                  bids.internal.create_unordered_list(bids.internal.format_path(event_files)));
    bids.internal.error_handling(mfilename(), 'noTrialTypeColumn', ...
                                 msg, ...
                                 tolerant, ...
                                 verbose);
    return
  end

  trial_type_list = unique(trial_type_list);
  idx = ismember(trial_type_list, trial_type_col);
  if any(idx)
    trial_type_list{idx} = [];
  end

  % n/a not included as trial type
  idx = ismember(trial_type_list, 'n/a');
  if any(idx)
    trial_type_list(idx) = [];
  end

end
