function copy_to_derivative(varargin)
  %
  % Copy selected data from BIDS layout to given derivatives folder,
  % returning layout of new derivatives folder
  %
  % USAGE::
  %
  %   bids.copy_to_derivative(BIDS, ...
  %                           'pipeline_name', '', ...
  %                           'out_path', '', ...
  %                           'filters', struct(), ...
  %                           'unzip', true, ...
  %                           'force', false, ...
  %                           'skip_dep', false, ...
  %                           'use_schema, use_schema, ...
  %                           'verbose', true);
  %
  %
  % :param BIDS:            BIDS directory name or BIDS structure (from bids.layout)
  % :type  BIDS:            structure or string
  %
  % :param pipeline_name:   name of pipeline to use
  % :type  pipeline_name:   string
  %
  % :param out_path:        path to directory containing the derivatives
  % :type  out_path:        string
  %
  % :param filter:          list of filters to choose what files to copy (see bids.query)
  % :type  filter:          structure or cell
  %
  % :param unzip:           If ``true`` then all ``.gz`` files will be unzipped
  %                         after being copied.
  % :type  unzip:           boolean
  %
  % :param force:           If set to ``false`` it will not overwrite any file already
  %                         present in the destination.
  % :type  force:           boolean
  %
  % :param skip_dep:        If set to ``false`` it will copy all the
  %                         dependencies of each file.
  % :type  skip_dep:        boolean
  %
  % :param use_schema:      If set to ``true`` it will only copy files
  %                         that are BIDS valid.
  % :type  use_schema:      boolean
  %
  % :param  verbose:
  % :type  verbose:         boolean
  %
  % All the metadata of each file is read through the whole hierarchy
  % and dumped into one side-car json file for each file copied.
  % In practice this "unravels" the inheritance principle.
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  default_pipeline_name = '';
  default_out_path = '';
  default_filter = struct();
  default_unzip = true;
  default_force = false;
  default_skip_dep = false;
  default_schema = true;
  default_verbose = false;

  args = inputParser;

  addRequired(args, 'BIDS');
  addParameter(args, 'pipeline_name', default_pipeline_name, @ischar);
  addParameter(args, 'out_path', default_out_path, @ischar);
  addParameter(args, 'filter', default_filter, @isstruct);
  addParameter(args, 'unzip', default_unzip);
  addParameter(args, 'force', default_force);
  addParameter(args, 'skip_dep', default_skip_dep);
  addParameter(args, 'use_schema', default_schema);
  addParameter(args, 'verbose', default_verbose);

  parse(args, varargin{:});

  BIDS = bids.layout(args.Results.BIDS, 'use_schema', args.Results.use_schema);

  % Check that we actually have to copy something
  data_list = bids.query(BIDS, 'data', args.Results.filter);
  subjects_list = bids.query(BIDS, 'subjects', args.Results.filter);

  if isempty(data_list)
    warning('No data found for this query');
    return
  else
    if args.Results.verbose
      fprintf('Found %d files in %d subjects\n', length(data_list), length(subjects_list));
    end
  end

  % Determine and create output directory
  out_path = args.Results.out_path;
  if isempty(out_path)
    out_path = fullfile(BIDS.pth, 'derivatives');
  end
  if ~exist(out_path, 'dir')
    bids.util.mkdir(out_path);
  end
  derivatives_folder = fullfile(out_path, args.Results.pipeline_name);
  if ~exist(derivatives_folder, 'dir')
    bids.util.mkdir(derivatives_folder);
  end

  ds_desc = bids.Description(args.Results.pipeline_name, BIDS);

  % Incase we are copying again to the output folder, we append that info to the
  % description otherwise we create a bran new dataset description for
  % derivatives
  descr_file = fullfile(derivatives_folder, 'dataset_description.json');
  if exist(descr_file, 'file')
    content = bids.util.jsondecode(descr_file);
    ds_desc = ds_desc.set_field(content);
    ds_desc = ds_desc.append('GeneratedBy', struct('Name', args.Results.pipeline_name));

  else
    ds_desc = bids.Description(args.Results.pipeline_name, BIDS);

  end

  ds_desc.write(derivatives_folder);

  copy_participants_tsv(BIDS, derivatives_folder, args);

  % looping over selected files
  for iFile = 1:numel(data_list)
    copy_file(BIDS, derivatives_folder, data_list{iFile}, ...
              args.Results.unzip, ...
              args.Results.force, ...
              args.Results.skip_dep, ...
              args.Results.verbose);
  end

  if args.Results.verbose
    fprintf('\n');
  end

  copy_session_scan_tsv(BIDS, derivatives_folder, args);

end

function copy_participants_tsv(BIDS, derivatives_folder, p)
  %
  % Very "brutal" approach where we copy the whole file
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
    copy_with_symlink(src, target, p.Results.unzip, p.Results.verbose);
    if exist(bids.internal.file_utils(src, 'ext', '.json'), 'file')
      copy_with_symlink(bids.internal.file_utils(src, 'ext', '.json'), ...
                        bids.internal.file_utils(target, 'ext', '.json'), ...
                        p.Results.unzip, ...
                        p.Results.verbose);
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

function copy_file(BIDS, derivatives_folder, data_file, unzip_files, force, skip_dep, verbose)

  info = bids.internal.return_file_info(BIDS, data_file);

  if ~isfield(info, 'sub_idx') || ~isfield(info, 'modality')
    % TODO: for we do not copy files in the root directory that have been indexed.
    return
  end

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
  % we follow any eventual symlink and gunzip the data
  copy_with_symlink(data_file, fullfile(out_dir, file.filename), unzip_files, verbose);

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

  copy_dependencies(file, BIDS, derivatives_folder, unzip_files, force, skip_dep, verbose);

end

function copy_with_symlink(src, target, unzip_files, verbose)
  %
  % TODO:
  % - test with actual datalad datasets on all OS
  %

  if verbose
    fprintf(1, '\n copying %s --> %s', src, target);
  end

  if  isunix

    if unzip_files && is_gunzipped(src)
      command = sprintf('gunzip -kfc %s > %s', src, target(1:end - 3));
    else
      command = sprintf('cp -R -L -f %s %s', src, target);
    end

    status = system(command);

    if status > 0 % throw warning
      msg = ['Copying data with system command failed: \n\t %s', src];
      bids.internal.error_handling(mfilename, 'copyError', msg, true, verbose);
    end

  elseif ispc
    msg = 'Unknown system: copy may fail';
    bids.internal.error_handling(mfilename, 'copyError', msg, true, verbose);
    use_copyfile(src, target, unzip_files, verbose);

  else
    use_copyfile(src, target, unzip_files, verbose);

  end

end

function use_copyfile(src, target, unzip_files, verbose)

  status = 1;

  if unzip_files && is_gunzipped(src)
    % Octave deletes the source file so we must copy and then unzip
    if bids.internal.is_octave()
      [status, message, messageId] = copyfile(src, target);
      gunzip(target);
    else
      gunzip(src, bids.internal.file_utils(target, 'path'));
    end
  else
    [status, message, messageId] = copyfile(src, target);
  end

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

function status = is_gunzipped(file)
  status = bids.internal.ends_with(file, '.gz');
end
