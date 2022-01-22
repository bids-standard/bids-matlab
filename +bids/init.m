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

  p = inputParser;

  addOptional(p, 'pth', default.pth, @ischar);
  addParameter(p, 'folders', default.folders, @isstruct);
  addParameter(p, 'is_derivative', default.is_derivative);
  addParameter(p, 'is_datalad_ds', default.is_datalad_ds);

  parse(p, varargin{:});

  %% Folder structure
  if ~isempty(fieldnames(p.Results.folders))

    subjects = create_folder_names(p, 'subjects');
    sessions = create_folder_names(p, 'sessions');

    bids.util.mkdir(p.Results.pth, ...
                    subjects, ...
                    sessions, ...
                    p.Results.folders.modalities);
  else
    bids.util.mkdir(p.Results.pth);
  end

  %% README
  pth_to_readmes = fullfile(fileparts(mfilename('fullpath')), '..', 'templates');
  src = fullfile(pth_to_readmes, 'README');
  if p.Results.is_datalad_ds
    src = fullfile(pth_to_readmes, 'README_datalad');
  end
  copyfile(src, fullfile(p.Results.pth, 'README'));

  %% dataset_description
  ds_desc = bids.Description();
  ds_desc.is_derivative = p.Results.is_derivative;
  ds_desc = ds_desc.set_derivative;
  ds_desc.write(p.Results.pth);

  %% CHANGELOG
  file_id = fopen(fullfile(p.Results.pth, 'CHANGES'), 'w');
  fprintf(file_id, '1.0.0 %s\n', datestr(now, 'yyyy-mm-dd'));
  fprintf(file_id, '- dataset creation.');
  fclose(file_id);

end

function folder_list = create_folder_names(p, folder_level)

  folder_list =  p.Results.folders.(folder_level);
  if ~iscell(folder_list)
    folder_list = {folder_list};
  end

  switch folder_level
    case 'subjects'
      prefix = 'sub-';
    case 'sessions'
      prefix = 'ses-';
  end

  if ~isempty(p.Results.folders.(folder_level))
    folder_list = cellfun(@(x) [prefix x], ...
                          p.Results.folders.(folder_level), ...
                          'UniformOutput', false);
  end

end
