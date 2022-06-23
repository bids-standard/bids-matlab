function trial_type_list = list_all_trial_types(BIDS, task)
  %
  % list all the *events.tsv files for that task
  % and make a list of all the trial_type
  %
  % USAGE::
  %
  %   trial_type_list = list_all_trial_types(BIDS, task)
  %
  %
  % (C) Copyright 2022 Remi Gau

  event_files = bids.query(BIDS, 'data', ...
                           'suffix', 'events', ...
                           'extension', '.tsv', ...
                           'task', task);

  trial_type_list = {};

  % TODO probably faster ways to do this than a nested loop
  for i = 1:size(event_files, 1)
    tmp = bids.util.tsvread(event_files{i, 1});
    if isfield(tmp, 'trial_type')
      for j = 1:numel(tmp.trial_type)
        trial_type_list{end + 1, 1} = tmp.trial_type{j}; %#ok<*AGROW>
      end
    end
  end

  trial_type_list = unique(trial_type_list);
  idx = ismember(trial_type_list, 'trial_type');
  if any(idx)
    trial_type_list{idx} = [];
  end

end
