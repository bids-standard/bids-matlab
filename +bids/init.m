function init(varargin)
  %
  % Initialize dataset with README, description, folder structure...
  %
  % USAGE::
  %
  %   init(pth, folders, is_derivative, is_datalad_ds)
  %
  % :param pth: directory where to create the dataset
  % :type  pth: string
  % :param folders: define the folder structure to create.
  %                 ``folders.subjects``
  %                 ``folders.sessions``
  %                 ``folders.modalities``
  % :type  folders: structure
  % :param is_derivative:
  % :type  is_derivative: boolean
  % :param is_datalad_ds:
  % :type  is_derivative: boolean
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
  addOptional(p, 'folders', default.folders, @isstruct);
  addOptional(p, 'is_derivative', default.is_derivative);
  addOptional(p, 'is_datalad_ds', default.is_datalad_ds);

  parse(p, varargin{:});

  %% Folder structure
  bids.util.mkdir(p.Results.pth, ...
                  p.Results.folders.subjects, ...
                  p.Results.folders.sessions, ...
                  p.Results.folders.modalities);

  %% README
  pth_to_readmes = fullfile(fileparts(mfilename('fullpath')), '..', 'templates');
  src = fullfile(pth_to_readmes, 'README');
  if p.Results.is_datalad_ds
    src = fullfile(pth_to_readmes, 'README_datalad');
  end
  copyfile(src, fullfile(p.Results.pth, 'README'));

  %% dataset_description
  ds_desc = bids.dataset_description;
  ds_desc = ds_desc.generate();
  ds_desc.is_derivative =  p.Results.is_derivative;
  ds_desc = ds_desc.set_derivative;
  ds_desc.write(p.Results.pth);

  %% CHANGELOG
  file_id = fopen(fullfile(p.Results.pth, 'CHANGES'), 'w');
  fprintf(file_id, '1.0.0 %s\n', datestr(now, 'YYYY-MM-DD'));
  fprintf(file_id, '- dataset creation.');
  fclose(file_id);

end
