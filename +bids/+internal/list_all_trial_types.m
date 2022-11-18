function trial_type_list = list_all_trial_types(varargin)
  %
  % list all the *events.tsv files for that task
  % and make a list of all the trial_type
  %
  % USAGE::
  %
  %   trial_type_list = bids.internal.list_all_trial_types(BIDS, task)
  %
  %

  % (C) Copyright 2022 Remi Gau

  default_tolerant = true;
  default_verbose = false;

  is_dir_or_struct = @(x) (isstruct(x) || isdir(x));

  args = inputParser();
  addRequired(args, 'BIDS', is_dir_or_struct);
  addRequired(args, 'task');
  addParameter(args, 'tolerant', default_tolerant);
  addParameter(args, 'verbose', default_verbose);

  parse(args, varargin{:});

  BIDS = args.Results.BIDS;
  task = args.Results.task;
  tolerant = args.Results.tolerant;
  verbose = args.Results.verbose;

  trial_type_list = {};

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
    content = bids.util.tsvread(event_files{i, 1});
    if isfield(content, 'trial_type')
      trial_type = content.trial_type;
      no_trial_type_column = false;
      if ~iscell(trial_type) && all(isnumeric(trial_type))
        trial_type = cellstr(num2str(trial_type));
      end
      trial_type_list = cat(1, trial_type_list, trial_type);
      trial_type_list = unique(trial_type_list);
    end
  end

  if no_trial_type_column
    msg = sprintf('No trial_type column found in files:%s', ...
                  bids.internal.create_unordered_list(bids.internal.format_path(event_files)));
    bids.internal.error_handling(mfilename(), 'noTrialTypeColumn', ...
                                 msg, ...
                                 tolerant, ...
                                 verbose);
    return
  end

  trial_type_list = unique(trial_type_list);
  idx = ismember(trial_type_list, 'trial_type');
  if any(idx)
    trial_type_list{idx} = [];
  end

end
