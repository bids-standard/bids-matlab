function derivatives = copy_to_derivative(BIDS, out_path, name, varargin)
  %
  % Copy selected data from BIDS layout to given derivatives folder,
  % returning layout of new derivatives folder
  %
  % USAGE::
  %
  %   derivatives = copy_to_derivative(BIDS, out_path, ...)
  %
  % :param BIDS:     BIDS directory name or BIDS structure (from bids.layout)
  % :type  BIDS:     (strcuture or string)
  % :param out_path: path to directory containing the derivatives
  % :type  out_path: string
  % :param name:     name of pipeline to use
  % :type  name:     string
  %
  %
  % __________________________________________________________________________
  %
  % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
  %   The brain imaging data structure, a format for organizing and
  %   describing outputs of neuroimaging experiments.
  %   K. J. Gorgolewski et al, Scientific Data, 2016.
  % __________________________________________________________________________

  % Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  narginchk(3, Inf);

  BIDS = bids.layout(BIDS);

  if ~exist(out_path, 'dir')
    mkdir(out_path);
  end

  derivatives = [];
  data_list = bids.query(BIDS, 'data', varargin{:});
  subjects_list = bids.query(BIDS, 'subjects', varargin{:});

  if isempty(data_list)
    warning('No data found for this query');
    return
  else
    fprintf('Found %d files in %d subjects\n', length(data_list), length(subjects_list));
  end

  pth_BIDSderiv = fullfile(out_path, name);
  if ~exist(pth_BIDSderiv, 'dir')
    mkdir(pth_BIDSderiv);
  end

  % creating / loading description
  descr_file = fullfile(pth_BIDSderiv, 'dataset_description.json');
  if exist(descr_file, 'file')
    description = bids.util.jsondecode(descr_file);
  else
    description = BIDS.description;
  end

  % Create / update GeneratedBy
  pipeline.Name = mfilename;
  pipeline.Version = '';
  pipeline.Container = varargin;
  if isfield(description, 'GeneratedBy')
    description.GeneratedBy = [description.GeneratedBy pipeline];
  else
    description.GeneratedBy = pipeline;
  end

  bids.util.jsonencode(descr_file, description, struct('Indent', '  '));

  % extracting participants.tsv file?

  % looping over selected files
  for iFile = 1:numel(data_list)
    copy_file(BIDS, pth_BIDSderiv, data_list{iFile});
  end

end

function status = copy_file(BIDS, derivatives_folder, data_file)

  status = true;

  info = bids.internal.return_file_info(BIDS, data_file);
  file = BIDS.subjects(info.sub_idx).(info.modality)(info.file_idx);

  out_dir = fullfile(derivatives_folder, ...
                     BIDS.subjects(info.sub_idx).name, ...
                     BIDS.subjects(info.sub_idx).session, ...
                     info.modality);

  meta_file = fullfile(out_dir, [bids.internal.file_utils(file.filename, 'basename') '.json']);

  %% ignore already existing files
  % avoid circular references
  if exist(meta_file, 'file')
    return
  else
    file.meta = bids.internal.get_metadata(file.metafile);
  end

  if ~exist(out_dir, 'dir')
    mkdir(out_dir);
  end

  %% copy data file
  if endsWith(file.ext, '.gz')
    % might be an issue with octave that removes original file
    gunzip(data_file, out_dir);
  else
    [status, message, messageId] = copyfile(data_file, fullfile(out_dir, file.filename));
  end
  if ~status
    warning([messageId ': ' message]);
    return
  end

  %% export metadata
  if ~strcmpi(file.ext, '.json') % skip if data file is json
    bids.util.jsonencode(meta_file, file.meta);
  end
  % checking that json is created
  if ~exist(meta_file, 'file')
    error('Failed to create sidecar json file: %s', meta_file);
  end

  %% dealing with dependencies
  if ~isempty(file.dependencies)
    dependencies = fieldnames(file.dependencies);
    for dep = 1:numel(dependencies)
      for idep = 1:numel(file.dependencies.(dependencies{dep}))
        dep_file = file.dependencies.(dependencies{dep}){idep};
        if exist(dep_file, 'file')
          copy_file(BIDS, derivatives_folder, dep_file);
        else
          warning(['Dependency file ' dep_file ' not found']);
        end
      end
    end
  end

end
