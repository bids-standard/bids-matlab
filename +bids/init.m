function init(varargin)
  %
  % Initialize dataset with README, description, folder structure...
  %
  % USAGE::
  %
  %   bids.init(pth, ...
  %             'folders', folders, ,...
  %             'is_derivative', false,...
  %             'is_datalad_ds', false, ...
  %             'tolerant', true, ...
  %             'verbose', false)
  %
  % :param pth: directory where to create the dataset
  % :type  pth: char
  %
  % :param folders: define the folder structure to create.
  %                 ``folders.subjects``
  %                 ``folders.sessions``
  %                 ``folders.modalities``
  % :type  folders: structure
  %
  % :param is_derivative:
  % :type  is_derivative: logical
  %
  % :param is_datalad_ds:
  % :type  is_derivative: logical
  %
  %

  % (C) Copyright 2021 BIDS-MATLAB developers

  default.pth = pwd;

  default.folders.subjects = '';
  default.folders.sessions = '';
  default.folders.modalities = '';
  default_tolerant = true;
  default_verbose = false;
  default.is_derivative = false;
  default.is_datalad_ds = false;

  is_logical = @(x) islogical(x);

  args = inputParser;

  addOptional(args, 'pth', default.pth, @ischar);
  addParameter(args, 'folders', default.folders, @isstruct);
  addParameter(args, 'is_derivative', default.is_derivative);
  addParameter(args, 'is_datalad_ds', default.is_datalad_ds);
  addParameter(args, 'tolerant', default_tolerant, is_logical);
  addParameter(args, 'verbose', default_verbose, is_logical);

  parse(args, varargin{:});

  is_datalad_ds = args.Results.is_datalad_ds;
  tolerant = args.Results.tolerant;
  verbose = args.Results.verbose;

  %% Folder structure
  if ~isempty(fieldnames(args.Results.folders))

    subjects = create_folder_names(args, 'subjects');
    if isfield(args.Results.folders, 'sessions')
      sessions = create_folder_names(args, 'sessions');
    else
      sessions = '';
    end

    modalities = validate_folder_list(args, 'modalities');

    bids.util.mkdir(args.Results.pth, ...
                    subjects, ...
                    sessions, ...
                    modalities);
  else
    bids.util.mkdir(args.Results.pth);
  end

  if exist('subjects', 'var') && ~isempty(subjects) && ~isempty(subjects{1})
    bids.util.create_participants_tsv(args.Results.pth, 'use_schema', false, ...
                                      'verbose', verbose, ...
                                      'tolerant', tolerant);
    if ~strcmp(sessions, '')
      bids.util.create_sessions_tsv(args.Results.pth, 'use_schema', false, ...
                                    'verbose', verbose, ...
                                    'tolerant', tolerant);
    end
  end

  bids.util.create_readme(args.Results.pth, is_datalad_ds, ...
                          'verbose', verbose, ...
                          'tolerant', tolerant);

  %% dataset_description
  ds_desc = bids.Description();
  ds_desc.is_derivative = args.Results.is_derivative;
  ds_desc = ds_desc.set_derivative;
  ds_desc.write(args.Results.pth);

  %% CHANGELOG
  file_id = fopen(fullfile(args.Results.pth, 'CHANGES'), 'w');
  fprintf(file_id, '1.0.0 %s\n', datestr(now, 'yyyy-mm-dd'));
  fprintf(file_id, '- dataset creation.');
  fclose(file_id);

end

function folder_list = validate_folder_list(args, folder_level)

  folder_list =  args.Results.folders.(folder_level);
  if ~iscell(folder_list)
    folder_list = {folder_list};
  end
  folder_list(cellfun('isempty', folder_list)) = [];

  only_alphanum = regexp(folder_list, '^[0-9a-zA-Z]+$');
  if any(cellfun('isempty', only_alphanum))
    msg = sprintf('BIDS labels must be alphanumeric only. Got:\n\t%s', ...
                  bids.internal.create_unordered_list(folder_list));
    bids.internal.error_handling(mfilename(), ...
                                 'nonAlphaNumFodler', ...
                                 msg, ...
                                 false);
  end
end

function folder_list = create_folder_names(args, folder_level)

  folder_list = validate_folder_list(args, folder_level);

  switch folder_level
    case 'subjects'
      prefix = 'sub-';
    case 'sessions'
      prefix = 'ses-';
  end

  if ~isempty(folder_list)

    folder_list = cellfun(@(x) [prefix x], ...
                          folder_list, ...
                          'UniformOutput', false);
  end

end
