function derivatives = derivate(BIDS, out_path, name, varargin)
  %
  % Copy selected data from BIDS layout to given derivatives folder,
  % returning layout of new derivatives folder
  %
  % USAGE::
  %
  %   derivatives = derivate(BIDS, out_path, ...)
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
    error(['Output path ' out_path ' not found']);
  end

  derivatives = [];
  data_list = bids.query(BIDS, 'data', varargin{:});
  subjects_list = bids.query(BIDS, 'subjects', varargin{:});

  if isempty(data_list)
    warning(['No data found for this query']);
    return;
  else
    fprintf('Found %d files in %d subjects\n', length(data_list), length(subjects_list));
  end

  pth_BIDSderiv = fullfile(out_path, name);
  if ~exist(pth_BIDSderiv,'dir')
    mkdir(pth_BIDSderiv);
  end

  % creating description
  descr_file = fullfile(pth_BIDSderiv, 'dataset_description.json');
  pipeline.Name = mfilename;
  % pipeline.Verion = ?
  pipeline.Container = varargin;

  % loading dataset description
  if exist(descr_file, 'file')
    description = bids.util.jsondecode(descr_file);
  else
    description = BIDS.description;
  end

  % updating GeneratedBy
  if isfield(description, 'GeneratedBy')
    description.GeneratedBy = [description.GeneratedBy pipeline];
  else
    description.GeneratedBy = [pipeline];
  end

  bids.util.jsonencode(descr_file, description, 'Indent', '  ');

  % extracting participants.tsv file?

  % looping over selected files
  for iFile = 1:numel(data_list)
    copy_file(BIDS, pth_BIDSderiv, data_list{iFile});
  end

end

function status = copy_file(BIDS, derivatives_folder, data_file)
  status = 1;
  info = bids.internal.return_file_info(BIDS, data_file);
  file = BIDS.subjects(info.sub_idx).(info.modality)(info.file_idx);
  basename = file.filename(1:end - length(file.ext));
  out_dir = fullfile(derivatives_folder,...
                     BIDS.subjects(info.sub_idx).name,...
                     BIDS.subjects(info.sub_idx).session,...
                     info.modality);
  out_path = fullfile(out_dir, basename);
  meta_file = [out_path '.json'];

  % ignore already existing files; avoid circular references
  if exist(meta_file) 
    return
  end
  if ~exist(out_dir, 'dir')
    mkdir(out_dir);
  end
  % copy data file
  if bids.internal.endsWith(file.ext, '.gz')
    gunzip(data_file, out_dir);
  else
    [status,message,messageId] = copyfile(data_file, [out_path file.ext]);
  end
  if ~status
    warning([messageId ': ' message]);
    return;
  end
  % export metadata
  if ~strcmpi(file.ext, '.json') % skip if data file is json
    bids.util.jsonencode(meta_file, file.meta);
  end

  % checking that json is created
  if ~exist(meta_file)
    error(['Failed to create sidecar json file: ' meta_file]);
  end

  % trating depandencies
  if ~isempty(file.dependencies)
    dependencies = fieldnames(file.dependencies);
    for dep = 1:numel(dependencies)
      for idep = 1: numel(file.dependencies.(dependencies{dep}))
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
