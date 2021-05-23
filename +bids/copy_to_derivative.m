function copy_to_derivative(varargin)
  %
  % Copy selected data from BIDS layout to given derivatives folder,
  % returning layout of new derivatives folder
  %
  % USAGE::
  %
  %   bids.copy_to_derivative(BIDS, ...
  %                               out_path, ...
  %                               pipeline_name, ...
  %                               filters, ...
  %                               'unzip', true, ...
  %                               'force', false...
  %                               'skip_dep', false ...
  %                               'verbose', true);
  %
  %
  % :param BIDS:            BIDS directory name or BIDS structure (from bids.layout)
  % :type  BIDS:            structure or string
  %
  % :param out_path:        path to directory containing the derivatives
  % :type  out_path:        string
  % :param pipeline_name:   name of pipeline to use
  % :type  pipeline_name:   string
  % :param filter:          list of filters to choose what files to copy (see bids.query)
  % :type  filter:          structure or cell
  %
  % PARAMETERS:
  %
  % :param unzip:           If ``true`` (default) then all ``.gz`` files will be unzipped
  %                         after being copied.
  % :type  unzip:           boolean
  % :param force:           If set to ``false`` (default) it will not overwrite any file already
  %                         present in the destination.
  % :type  force:           boolean
  % :param skip_dep:        If set to ``false`` (default) it will copy all the
  %                         dependencies of each file.
  % :type  skip_dep:        boolean
  % :param use_schema:      If set to ``true`` (default) it will only copy files
  %                         that are BIDS valid.
  % :type  use_schema:      boolean
  % :param  verbose:
  % :type  verbose:         boolean
  %
  % All the metadata of each file is read through the whole hierarchy
  % and dumped into one side-car json file for each file copied.
  % In practice this "unravels" the inheritance principle.
  %
  %
  % __________________________________________________________________________
  %
  % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
  %   The brain imaging data structure, a format for organizing and
  %   describing outputs of neuroimaging experiments.
  %   K. J. Gorgolewski et al, Scientific Data, 2016.
  % __________________________________________________________________________
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  default_out_path = fullfile(pwd, 'derivatives');
  default_pipeline_name = 'bids-matlab';
  default_filter = struct();

  default_unzip = true;
  default_force = false;
  default_skip_dep = false;
  default_schema = true;
  default_verbose = false;

  p = inputParser;

  addRequired(p, 'BIDS');

  addOptional(p, 'out_path', default_out_path, @ischar);
  addOptional(p, 'pipeline_name', default_pipeline_name, @ischar);
  addOptional(p, 'filter', default_filter, @isstruct);

  addParameter(p, 'unzip', default_unzip);
  addParameter(p, 'force', default_force);
  addParameter(p, 'skip_dep', default_skip_dep);
  addParameter(p, 'use_schema', default_schema);
  addParameter(p, 'verbose', default_verbose);

  parse(p, varargin{:});

  BIDS = bids.layout(p.Results.BIDS, p.Results.use_schema);

  % Check that we actually have to copy something
  data_list = bids.query(BIDS, 'data', p.Results.filter);
  subjects_list = bids.query(BIDS, 'subjects', p.Results.filter);

  if isempty(data_list)
    warning('No data found for this query');
    return
  else
    fprintf('Found %d files in %d subjects\n', length(data_list), length(subjects_list));
  end

  % Determine and create output directory
  out_path = p.Results.out_path;
  if isempty(out_path)
    out_path = fullfile(BIDS.dir, '..', 'derivatives');
  end
  if ~exist(out_path, 'dir')
    mkdir(out_path);
  end
  derivatives_folder = fullfile(out_path, p.Results.pipeline_name);
  if ~exist(derivatives_folder, 'dir')
    mkdir(derivatives_folder);
  end

  % Creating / loading description
  descr_file = fullfile(derivatives_folder, 'dataset_description.json');
  if exist(descr_file, 'file')
    description = bids.util.jsondecode(descr_file);
  else
    description = BIDS.description;
  end

  % Create / update GeneratedBy
  pipeline.Name = p.Results.pipeline_name;
  pipeline.Version = '';
  pipeline.Container = '';
  if isfield(description, 'GeneratedBy')
    description.GeneratedBy = [description.GeneratedBy; pipeline];
  else
    description.GeneratedBy = pipeline;
  end

  bids.util.jsonencode(descr_file, description, struct('Indent', '  '));

  % extracting participants.tsv file?

  % looping over selected files
  for iFile = 1:numel(data_list)
    copy_file(BIDS, derivatives_folder, data_list{iFile}, ...
              p.Results.unzip, ...
              p.Results.force, ...
              p.Results.skip_dep, ...
              p.Results.verbose);
  end

end

function copy_file(BIDS, derivatives_folder, data_file, unzip, force, skip_dep, verbose)

  info = bids.internal.return_file_info(BIDS, data_file);
  file = BIDS.subjects(info.sub_idx).(info.modality)(info.file_idx);

  out_dir = fullfile(derivatives_folder, ...
                     BIDS.subjects(info.sub_idx).name, ...
                     BIDS.subjects(info.sub_idx).session, ...
                     info.modality);

  output_metadata_file = fullfile(out_dir, ...
                                  strrep(file.filename, file.ext, '.json'));

  %% ignore already existing files
  % avoid circular references
  if ~force && exist(fullfile(out_dir, file.filename), 'file')
    if verbose
      fprintf(1, '\n skipping: %s', file.filename);
    end
    return
  else
    if verbose
      fprintf(1, '\n copying: %s', file.filename);
    end
    file.meta = bids.internal.get_metadata(file.metafile);
  end

  if ~exist(out_dir, 'dir')
    mkdir(out_dir);
  end

  %% copy data file
  % we follow any eventual symlink
  % and then unzip the data if necessary
  copy_with_symlink(data_file, fullfile(out_dir, file.filename));
  unzip_data(file, out_dir, unzip);

  %% export metadata
  % All the metadata of each file is read through the whole hierarchy
  % and dumped into one side-car json file for each file copied
  % In practice this "unravels" the inheritance principle
  if ~strcmpi(file.ext, '.json') % skip if data file is json
    bids.util.jsonencode(output_metadata_file, file.meta);
  end
  % checking that json is created
  if ~exist(output_metadata_file, 'file')
    error('Failed to create sidecar json file: %s', output_metadata_file);
  end

  copy_dependencies(file, BIDS, derivatives_folder, unzip, force, skip_dep, verbose);

end

function copy_with_symlink(src, target)
  %
  % Follows symbolic link to copy data:
  % Might be necessary for datasets curated with datalad
  %
  % Comment from Guillaume:
  %   I think we should make a system() call only out of necessity.
  %   We could test for symlinks within a isunix condition and only use cp -L for these?
  %
  % Though datalad should run on windows too
  %

  command = 'cp -R -L -f';

  try
    status = system( ...
                    sprintf('%s %s %s', ...
                            command, ...
                            src, ...
                            target));

    if status > 0
      message = [ ...
                 'Copying data with system command failed: ' ...
                 'Are you running Windows?\n', ...
                 'Will use matlab/octave copyfile command instead.\n', ...
                 'May be an issue if your data set contains symbolic links' ...
                 '(e.g. if you use datalad or git-annex.)'];
      error(message);
    end

  catch

    fprintf(1, 'Using octave/matlab to copy files.');
    [status, message, messageId] = copyfile(src, target);
    if ~status
      warning([messageId ': ' message]);
      return
    end

  end

end

function copy_dependencies(file, BIDS, derivatives_folder, unzip, force, skip_dep, verbose)

  if ~skip_dep

    dependencies = fieldnames(file.dependencies);

    for dep = 1:numel(dependencies)
      for ifile = 1:numel(file.dependencies.(dependencies{dep}))

        dep_file = file.dependencies.(dependencies{dep}){ifile};
        if exist(dep_file, 'file')
          % recursive call but by skipping dependencies of the dependencies
          % to avoid infinite loop when using "force = true"
          copy_file(BIDS, derivatives_folder, dep_file, unzip, force, ~skip_dep, verbose);
        else
          warning(['Dependency file ' dep_file ' not found']);
        end

      end
    end

  end

end

function unzip_data(file, out_dir, unzip)
  if ~unzip
    return
  end
  % to ensure a consistent behavior with matlab and octave
  if bids.internal.ends_with(file.ext, '.gz')
    gunzip(fullfile(out_dir, file.filename));
    if exist(fullfile(out_dir, file.filename), 'file')
      delete(fullfile(out_dir, file.filename));
    end
  end
end
