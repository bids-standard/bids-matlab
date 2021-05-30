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
    if p.Results.verbose
      fprintf('Found %d files in %d subjects\n', length(data_list), length(subjects_list));
    end
  end

  % Determine and create output directory
  out_path = p.Results.out_path;
  if isempty(out_path)
    out_path = fullfile(BIDS.pth, '..', 'derivatives');
  end
  if ~exist(out_path, 'dir')
    mkdir(out_path);
  end
  derivatives_folder = fullfile(out_path, p.Results.pipeline_name);
  if ~exist(derivatives_folder, 'dir')
    mkdir(derivatives_folder);
  end

  % Creating / loading description
  ds_desc = bids.dataset_description;

  % Incase we are copying again to the output folder, we append that info to the
  % description otherwise we create a bran new dataset description for
  % derivatives
  descr_file = fullfile(derivatives_folder, 'dataset_description.json');
  if exist(descr_file, 'file')
    content = bids.util.jsondecode(descr_file);
    ds_desc = ds_desc.set_field(content);
    ds_desc = ds_desc.append('GeneratedBy', struct('Name', p.Results.pipeline_name));

  else
    ds_desc = ds_desc.generate(p.Results.pipeline_name, BIDS);

  end

  ds_desc.write(derivatives_folder);

  copy_participants_tsv(BIDS, derivatives_folder, p);

  % looping over selected files
  for iFile = 1:numel(data_list)
    copy_file(BIDS, derivatives_folder, data_list{iFile}, ...
              p.Results.unzip, ...
              p.Results.force, ...
              p.Results.skip_dep, ...
              p.Results.verbose);
  end

  if p.Results.verbose
    fprintf('\n');
  end

  copy_session_scan_tsv(BIDS, derivatives_folder, p);

end

function copy_participants_tsv(BIDS, derivatives_folder, p)
  %
  % Very "brutal" approach wehere we copy the whole file
  %
  % TODO:
  %   -  if only certain subjects are copied only copy those entries from the TSV
  %

  if ~isempty(BIDS.participants)

    src = fullfile(BIDS.pth, 'participants.tsv');
    target = fullfile(derivatives_folder, 'participants.tsv');

    copy_tsv(src, target, p);

  end
end

function copy_tsv(src, target, p)

  flag = false;
  if p.Results.force
    flag = true;
  else
    if exist(target, 'file') == 0
      flag = true;
    end
  end

  if flag
    copy_with_symlink(src, target, p.Results.verbose);
    if exist(bids.internal.file_utils(src, 'ext', '.json'), 'file')
      copy_with_symlink(bids.internal.file_utils(src, 'ext', '.json'), ...
                        bids.internal.file_utils(target, 'ext', '.json'));
    end
  end

end

function copy_session_scan_tsv(BIDS, derivatives_folder, p)
  %
  % Very "brutal" approach wehere we copy the whole file
  %
  % TODO:
  %   -  only copy the entries of the sessions / files that are copied
  %

  % identify in the BIDS layout the subjects / sessions combination that we
  % need to keep to copy
  subjects_list = bids.query(BIDS, 'subjects', p.Results.filter);
  sessions_list = bids.query(BIDS, 'sessions', p.Results.filter);

  subjects = {BIDS.subjects.name}';
  subjects = cellfun(@(x) x(5:end), subjects, 'UniformOutput', false);
  sessions = {BIDS.subjects.session}';
  sessions = cellfun(@(x) x(5:end), sessions, 'UniformOutput', false);

  keep = find(all([ismember(subjects, subjects_list) ismember(sessions, sessions_list)], 2));

  for i = 1:numel(keep)

    if ~isempty(BIDS.subjects(keep(i)).sess)
      src = BIDS.subjects(keep(i)).sess;
      target = fullfile(derivatives_folder, ...
                        BIDS.subjects(keep(i)).name, ...
                        bids.internal.file_utils(src, 'filename'));
      copy_tsv(src, target, p);
    end

    if ~isempty(BIDS.subjects(keep(i)).scans)
      src = BIDS.subjects(keep(i)).scans;
      target = fullfile(derivatives_folder, ...
                        BIDS.subjects(keep(i)).name, ...
                        BIDS.subjects(keep(i)).session, ...
                        bids.internal.file_utils(src, 'filename'));
      copy_tsv(src, target, p);
    end

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
    file.meta = bids.internal.get_metadata(file.metafile);
  end

  if ~exist(out_dir, 'dir')
    mkdir(out_dir);
  end

  %% copy data file
  % we follow any eventual symlink
  % and then unzip the data if necessary
  copy_with_symlink(data_file, fullfile(out_dir, file.filename), verbose);
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

function copy_with_symlink(src, target, verbose)
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

  if verbose
    fprintf(1, '\n copying %s --> %s', src, target);
  end

    if  isunix
        status = system( ...
                        sprintf('%s %s %s', ...
                                command, ...
                                src, ...
                                target));
        if status > 0
          msg = ['Copying data with system command failed: ' ...
                 'Will use matlab/octave copyfile command instead.\n', ...
                 'May be an issue if your data set contains symbolic links' ...
                 '(e.g. if you use datalad or git-annex.)'];
          bids.internal.error_handling(mfilename, 'copyError', msg, true, verbose);
          use_copyfile(src, target, verbose);
        end
        
    else
        use_copyfile(src, target, verbose);
    end

end

function use_copyfile(src, target, verbose)
    [status, message, messageId] = copyfile(src, target);
    if ~status
      msg = [messageId ': ' message];
      bids.internal.error_handling(mfilename, 'copyError', msg, false, verbose);
    end
end

function copy_dependencies(file, BIDS, derivatives_folder, unzip, force, skip_dep, verbose)

  if ~skip_dep

    dependencies = fieldnames(file.dependencies);

    for dep = 1:numel(dependencies)

      %         % TODO
      %         % Dirty hack to prevent the copy of ASL data to crash here.
      %         % But this means that dependencies of ASL data will not be copied until
      %         % this is fixed.
      %         if ismember(dependencies{dep}, {'context', 'm0'})
      %             continue
      %         end

      for ifile = 1:numel(file.dependencies.(dependencies{dep}))

        dep_file = file.dependencies.(dependencies{dep}){ifile};
        if exist(dep_file, 'file')
          % recursive call but by skipping dependencies of the dependencies
          % to avoid infinite loop when using "force = true"
          copy_file(BIDS, derivatives_folder, dep_file, unzip, force, ~skip_dep, verbose);
        else

          msg = sprintf('Dependency file %s not found', dep_file);
          bids.internal.error_handling(mfilename, 'missingDependencyFile', msg, true, verbose);

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
