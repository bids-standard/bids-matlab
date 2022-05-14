function init(varargin)
  %
  % Initialize dataset with README, description, folder structure...
  %
  % USAGE::
  %
  %   bids.init(pth, ...
  %             'folders', folders, ,...
  %             'is_derivative', false,...
  %             'is_datalad_ds', false)
  %
  % :param pth: directory where to create the dataset
  % :type  pth: string
  %
  % :param folders: define the folder structure to create.
  %                 ``folders.subjects``
  %                 ``folders.sessions``
  %                 ``folders.modalities``
  % :type  folders: structure
  %
  % :param is_derivative:
  % :type  is_derivative: boolean
  %
  % :param is_datalad_ds:
  % :type  is_derivative: boolean
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  default.pth = pwd;

  default.folders.subjects = '';
  default.folders.sessions = '';
  default.folders.modalities = '';

  default.is_derivative = false;
  default.is_datalad_ds = false;

  args = inputParser;

  addOptional(args, 'pth', default.pth, @ischar);
  addParameter(args, 'folders', default.folders, @isstruct);
  addParameter(args, 'is_derivative', default.is_derivative);
  addParameter(args, 'is_datalad_ds', default.is_datalad_ds);

  parse(args, varargin{:});

  %% Folder structure
  if ~isempty(fieldnames(args.Results.folders))

    subjects = create_folder_names(args, 'subjects');
    if isfield(args.Results.folders, 'sessions')
      sessions = create_folder_names(args, 'sessions');
    else
      sessions = '';
    end

    bids.util.mkdir(args.Results.pth, ...
                    subjects, ...
                    sessions, ...
                    args.Results.folders.modalities);
  else
    bids.util.mkdir(args.Results.pth);
  end

  %% README
  pth_to_readmes = fullfile(fileparts(mfilename('fullpath')), '..', 'templates');
  src = fullfile(pth_to_readmes, 'README');
  if args.Results.is_datalad_ds
    src = fullfile(pth_to_readmes, 'README_datalad');
  end
  copyfile(src, fullfile(args.Results.pth, 'README'));

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

function folder_list = create_folder_names(args, folder_level)

  folder_list =  args.Results.folders.(folder_level);
  if ~iscell(folder_list)
    folder_list = {folder_list};
  end

  switch folder_level
    case 'subjects'
      prefix = 'sub-';
    case 'sessions'
      prefix = 'ses-';
  end

  if ~isempty(args.Results.folders.(folder_level))
    folder_list = cellfun(@(x) [prefix x], ...
                          args.Results.folders.(folder_level), ...
                          'UniformOutput', false);
  end

end
