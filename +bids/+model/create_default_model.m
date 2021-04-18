function [content, filename] = create_default_model(BIDS, task_name)
  %
  % Creates a default model json file.
  %
  % This model has 3 "steps" in that order:
  %
  % - Subject / Run level:
  %   - will create a GLM with a design matrix that includes all
  %     all the possible type of trial_types that exist across
  %     all subjects and runs for the task specified.
  %
  % - Subject level:
  %   - use AutoContrasts to generate contrasts for all each trial_type
  %     across runs
  %
  % - Run level:
  %   - use AutoContrasts to generate contrasts for each trial_type
  %     for each run. This can be useful to run MVPA analysis on the beta
  %     images of each run.
  %
  % - Dataset level:
  %   - use AutoContrasts to generate contrasts for each trial_type
  %     for at the group level.
  %
  % USAGE::
  %
  %   [content, filename] = create_default_model(BIDS, task_name)
  %
  % :output:
  %
  %
  % (C) Copyright 2020 CPP_SPM developers

  trialTypeList = list_all_trial_types(BIDS, task_name);

  content = bids.model.return_empty_model();

  content = design_matrix_and_contrasts(content, trialTypeList);

  content.Name = task_name;
  content.Description = ['default model for ' task_name];
  content.Input.task = task_name;

  filename = ['model-default' task_name '_smdl.json'];

end

function trial_type_list = list_all_trial_types(BIDS, task_name)
  %
  % list all the *events.tsv files for that task
  % and make a list of all the trial_types
  %

  event_files = bids.query(BIDS, 'data', ...
                           'suffix', 'events', ...
                           'extension', '.tsv', ...
                           'task', task_name);

  trial_type_list = {};

  for iFile = 1:size(event_files, 1)
    tmp = bids.util.tsvread(event_files{iFile, 1});
    for iTrialType = 1:numel(tmp.trial_type)
      trial_type_list{end + 1, 1} = tmp.trial_type{iTrialType}; %#ok<*AGROW>
    end
  end

  trial_type_list = unique(trial_type_list);
  idx = ismember(trial_type_list, 'trial_type');
  if any(idx)
    trial_type_list{idx} = [];
  end

end

function content = design_matrix_and_contrasts(content, trialTypeList)

  for iTrialType = 1:numel(trialTypeList)

    if  ~isempty(trialTypeList{iTrialType})
      trial_type_name = ['trial_type.' trialTypeList{iTrialType}];

      % subject
      content.Steps{1}.Model.X{iTrialType} = trial_type_name;

      % run
      content.Steps{2}.Model.X{iTrialType} = trial_type_name;

      for iStep = 1:numel(content.Steps)
        content.Steps{iStep}.AutoContrasts{iTrialType} = trial_type_name;
      end
    end

  end

end
