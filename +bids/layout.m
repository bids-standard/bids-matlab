function BIDS = layout(varargin)
  %
  % Parse a directory structure formated according to the BIDS standard
  %
  % USAGE::
  %
  %   BIDS = bids.layout(pwd, ...
  %                      'use_schema', true, ...
  %                      'index_derivatives', false, ...
  %                      'tolerant', true, ...
  %                      'verbose', false)
  %
  % :param root:       directory of the dataset formated according to BIDS
  %                    [default: ``pwd``]
  % :type  root:       string
  %
  % :param use_schema: If set to ``true``, the parsing of the dataset
  %                    will follow the bids-schema provided with bids-matlab.
  %                    If set to ``false`` files just have to be of the form
  %                    ``sub-label_[entity-label]_suffix.ext`` to be parsed.
  %                    If a folder path is provided, then the schema contained
  %                    in that folder will be used for parsing.
  % :type  use_schema: boolean
  %
  % :param index_derivatives: if ``true`` this will index the content of the
  %                           any ``derivatives`` folder in the BIDS dataset.
  % :type  index_derivatives: boolean
  %
  % :param tolerant: Set to ``true`` to turn validation errors into warnings
  % :type  tolerant: boolean
  %
  % :param verbose: Set to ``true`` to get more feedback
  % :type  verbose: boolean
  %
  %
  % (C) Copyright 2016-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  %% Validate input arguments
  % ==========================================================================

  default_root = pwd;
  default_index_derivatives = false;
  default_tolerant = true;
  default_use_schema = true;
  default_verbose = false;

  isDirOrStruct = @(x) (isstruct(x) || isdir(x));

  args = inputParser();

  addOptional(args, 'root', default_root, isDirOrStruct);
  addParameter(args, 'index_derivatives', default_index_derivatives);
  addParameter(args, 'tolerant', default_tolerant);
  addParameter(args, 'use_schema', default_use_schema);
  addParameter(args, 'verbose', default_verbose);

  parse(args, varargin{:});

  root = args.Results.root;
  index_derivatives = args.Results.index_derivatives;
  tolerant = args.Results.tolerant;
  use_schema = args.Results.use_schema;
  verbose = args.Results.verbose;

  if ischar(root)
    root = bids.internal.file_utils(root, 'CPath');

  elseif isstruct(root)
    BIDS = root; % for bids.query
    return

  else
    error('Invalid syntax.');

  end

  %% BIDS structure
  % ==========================================================================
  % BIDS.dir          -- BIDS directory
  % BIDS.description  -- content of dataset_description.json
  % BIDS.sessions     -- cellstr of sessions
  % BIDS.participants -- for participants.tsv
  % BIDS.subjects     -- structure array of subjects
  % BIDS.root         -- tsv and json files in the root folder

  BIDS = struct( ...
                'pth', root, ...
                'description', struct([]), ...
                'sessions', {{}}, ...
                'participants', struct([]), ...
                'subjects', struct([]));

  BIDS = validate_description(BIDS, tolerant, verbose);

  %% Optional directories
  % ==========================================================================
  % [code/] - ignore
  % [derivatives/]
  % [stimuli/] - ingore
  % [sourcedata/] - ignore
  % [phenotype/]

  BIDS.participants = [];
  BIDS.participants = manage_tsv(BIDS.participants, BIDS.pth, 'participants.tsv', verbose);

  BIDS = index_root_directory(BIDS);

  %% Subjects
  % ==========================================================================
  subjects = cellstr(bids.internal.file_utils('List', BIDS.pth, 'dir', '^sub-.*$'));
  if isequal(subjects, {''})
    msg = sprintf('No subjects found in BIDS directory: ''%s''', ...
                  BIDS.pth);
    bids.internal.error_handling(mfilename, 'noSubject', msg, tolerant, verbose);
    return
  end

  schema = bids.Schema(use_schema);
  schema.verbose = verbose;

  for iSub = 1:numel(subjects)
    sessions = cellstr(bids.internal.file_utils('List', ...
                                                fullfile(BIDS.pth, subjects{iSub}), ...
                                                'dir', ...
                                                '^ses-.*$'));

    for iSess = 1:numel(sessions)
      if isempty(BIDS.subjects)
        BIDS.subjects = parse_subject(BIDS.pth, subjects{iSub}, sessions{iSess}, schema, verbose);

      else
        new_subject = parse_subject(BIDS.pth, subjects{iSub}, sessions{iSess}, schema, verbose);
        [BIDS.subjects, new_subject] = bids.internal.match_structure_fields(BIDS.subjects, ...
                                                                            new_subject);
        % TODO: this can be added to "match_structure_fields"
        BIDS.subjects(end + 1) = new_subject;

      end

    end

  end

  BIDS = manage_dependencies(BIDS, verbose);

  BIDS = index_derivatives_dir(BIDS, index_derivatives, verbose);

end

function BIDS = index_root_directory(BIDS)
  % index json and tsv files in the root directory
  files_to_exclude = {'participants', ... already done
                      'dataset_description', ...
                      'genetic_info', ... % because it messes the parse_filename
                      '(.bids-validator-config)' ...
                     };

  pattern = ['^(?!', strjoin(files_to_exclude, '|'), ').*.(tsv)$'];

  files_in_root = bids.internal.file_utils('FPList', BIDS.pth, pattern);
  BIDS.root = struct([]);
  for i = 1:size(files_in_root, 1)
    new_file = bids.internal.parse_filename(files_in_root(i, :));
    if isempty(new_file)
      continue
    end
    if isempty(BIDS.root)
      BIDS.root = new_file;
    else
      [BIDS.root, new_file] = bids.internal.match_structure_fields(BIDS.root, new_file);
      BIDS.root(end + 1) = new_file;
    end
  end

end

function BIDS = index_derivatives_dir(BIDS, idx_deriv, verbose)
  if idx_deriv && exist(fullfile(BIDS.pth, 'derivatives'), 'dir')

    der_folders = cellstr(bids.internal.file_utils('List', ...
                                                   fullfile(BIDS.pth, 'derivatives'), ...
                                                   'dir', ...
                                                   '.*'));

    for iDir = 1:numel(der_folders)
      BIDS.derivatives.(der_folders{iDir}) = bids.layout( ...
                                                         fullfile(BIDS.pth, ...
                                                                  'derivatives', ...
                                                                  der_folders{iDir}), ...
                                                         'use_schema', false, ...
                                                         'index_derivatives', idx_deriv, ...
                                                         'tolerant', true, ...
                                                         'verbose', verbose);
    end

  end
end

function subject = parse_subject(pth, subjname, sesname, schema, verbose)
  %
  % Parse a subject's directory
  %
  % For each modality (anat, func, eeg...) all the files from the
  % corresponding directory are listed and their filenames parsed with
  % BIDS valid entities as listed in the schema (if the schema is not empty).

  subject.name    = subjname;   % subject name ('sub-<label>')
  subject.path    = fullfile(pth, subjname, sesname); % full path to subject directory
  subject.session = sesname;    % session name ('' or 'ses-<label>')

  % for sub-<label>_sessions.tsv
  % NOTE: this will end up being the same file when subject
  %       has several sessions
  subject.sess = bids.internal.file_utils('FPList', ...
                                          return_subject_path(subject),  ...
                                          ['^' subjname, '_sessions.tsv' '$']);

  % for sub-<label>[_ses-<label>]_scans.tsv
  % NOTE: *_scans.json files can stored at the root level
  %       and this should implemented when querying scans.tsv content + metadata
  subject.scans = bids.internal.file_utils('FPList', ...
                                           subject.path,  ...
                                           ['^' subjname, '.*_scans.tsv' '$']);

  modality_groups = schema.return_modality_groups();

  for iGroup = 1:numel(modality_groups)

    modalities = schema.return_modalities(subject, modality_groups{iGroup});

    % if we go schema-less, we pass an empty schema.content to all the parsing functions
    % so the parsing is unconstrained
    for iModality = 1:numel(modalities)
      switch modalities{iModality}
        case {'anat', 'func', 'beh', 'meg', 'eeg', 'ieeg', 'pet', 'fmap', 'dwi', 'perf', 'micr'}
          subject = parse_using_schema(subject, modalities{iModality}, schema, verbose);
        otherwise
          % in case we are going schemaless
          % and the modality is not one of the usual suspect
          subject.(modalities{iModality}) = struct([]);
          subject = parse_using_schema(subject, modalities{iModality}, schema, verbose);
      end
    end

  end

end

function subject = parse_using_schema(subject, modality, schema, verbose)

  pth = fullfile(subject.path, modality);

  if exist(pth, 'dir')

    subject = bids.internal.add_missing_field(subject, modality);

    file_list = return_file_list(modality, subject, schema);

    % dependency previous file
    previous = struct('group', struct('index', 0, 'base', '', 'len', 1), ...
                      'data', struct('index', 0, 'base', '', 'len', 1), ...
                      'allowed_ext', []);

    for iFile = 1:size(file_list, 1)

      [subject, status, previous] = bids.internal.append_to_layout(file_list{iFile}, ...
                                                                   subject, ...
                                                                   modality, ...
                                                                   schema,  ...
                                                                   previous);

      if status

        [subject, previous] = index_dependencies(subject, ...
                                                 modality, ...
                                                 file_list{iFile}, ...
                                                 iFile, ...
                                                 previous);

        switch subject.(modality)(end).suffix

          case 'asl'

            subject.(modality)(end).meta = [];

            metafile = subject.(modality)(iFile).metafile;
            subject.(modality)(end).meta = bids.internal.get_metadata(metafile);

            aslcontext_file = strrep(subject.perf(end).filename, ...
                                     ['_asl' subject.perf(end).ext], ...
                                     '_aslcontext.tsv');
            subject.(modality)(end).dependencies.context = manage_tsv( ...
                                                                      struct('content', [], ...
                                                                             'meta', []), ...
                                                                      pth, ...
                                                                      aslcontext_file, ...
                                                                      verbose);

            subject.(modality)(end) = manage_M0(subject.perf(end), pth, verbose);

        end

      end

    end

  end

end

function BIDS = validate_description(BIDS, tolerant, verbose)

  if ~exist(fullfile(BIDS.pth, 'dataset_description.json'), 'file')

    msg = sprintf('BIDS directory not valid: missing dataset_description.json: ''%s''', ...
                  BIDS.pth);
    bids.internal.error_handling(mfilename, 'missingDescripton', msg, tolerant, verbose);

  end
  try
    BIDS.description = bids.util.jsondecode(fullfile(BIDS.pth, 'dataset_description.json'));
  catch err
    msg = sprintf('BIDS dataset description could not be read: %s', err.message);
    bids.internal.error_handling(mfilename, 'cannotReadDescripton', msg, tolerant, verbose);
  end

  fields_to_check = {'BIDSVersion', 'Name'};
  for iField = 1:numel(fields_to_check)

    if ~isfield(BIDS.description, fields_to_check{iField})
      msg = sprintf( ...
                    'BIDS dataset description not valid: missing %s field.', ...
                    fields_to_check{iField});
      bids.internal.error_handling(mfilename, 'invalidDescripton', msg, tolerant, verbose);
    end

    % TODO
    % Add warning if bids version does not match schema version

  end

end

function f = convert_to_cell(f)
  if isempty(f)
    f = {};
  else
    f = cellstr(f);
  end
end

function subject_path = return_subject_path(subject)
  % get "subject path" without the session folder (if it exists)
  subject_path = subject.path;
  tmp = bids.internal.file_utils(subject_path, 'filename');
  if strcmp(tmp(1:3), 'ses')
    subject_path = bids.internal.file_utils(subject_path, 'path');
  end
end

function file_list = return_file_list(modality, subject, schema)

  % We list files followiung those rules:
  %  - anything but json files
  %  - requesting strart with sub-<subId>_ses-<sesId>_
  %  - requesting a set of entities of form <key>-<value>_
  %  - requestin exactly one suffix
  %
  %  When not using the schema, listed files
  %  - can inlude a prefix
  %  - can be json

  % TODO
  % it should be possible to create some of those patterns for the regexp
  % based on some of the required entities written down in the schema

  % TODO
  % this does not cover coordsystem.json

  % prefix only for shemaless data
  if isempty(schema.content)
    prefix = '^([a-zA-Z0-9_]*)';
  else
    prefix = '^';
  end

  % sub and ses part
  pattern = [prefix subject.name '_'];
  if ~isempty(subject.session)
    pattern = [pattern subject.session '_'];
  end

  % entities
  pattern = [pattern '([a-zA-Z0-9]+-[a-zA-Z0-9]+_)*'];

  % suffix
  pattern = [pattern '([a-zA-Z0-9]+\.){1}'];

  % extension
  % JSON files are not indexed
  pattern = [pattern '(?!json)'];
  pattern = [pattern '([a-zA-Z0-9.]+){1}$'];

  pth = fullfile(subject.path, modality);

  [file_list, d] = bids.internal.file_utils('List', ...
                                            pth, ...
                                            pattern);

  file_list = convert_to_cell(file_list);

  % Consider removing 'strcmp(modality, 'meg') &&'
  % just to cover eventual other modalities that stores data
  % in folders
  if strcmp(modality, 'meg') && ~isempty(d)
    for i = 1:size(d, 1)
      file_list{end + 1, 1} = d(i, :); %#ok<*AGROW>
    end
  end

end

function [subject, previous] = index_dependencies(subject, modality, file, i, previous)
  %
  % Each file structure contains dependencies sub-structure with guaranteed fields:
  %
  % - explicit: list of data files containing "IntendedFor" referencing current file.
  %              see the manage_dependencies function
  %
  % - data:     list of files with same name but different extension.
  %              This combines files that are split in header and data
  %              (like in Brainvision), also takes care of bval/bvec files
  %
  % - group:    list of files that have same name except extension and suffix.
  %              This groups file that logically need each other,
  %              like functional mri and events tabular file.
  %              It also takes care of fmap magnitude1/2 and phasediff.

  pth = fullfile(subject.path, modality);
  fullpath_filename = fullfile(pth, file);

  % Checking dependencies
  if same_group(file, previous)

    % same data
    if same_data(file, previous)

      for di = previous.data.index:numel(subject.(modality)) - 1
        subject.(modality)(di).dependencies.data{end + 1, 1} = fullpath_filename;
      end

      % not same data but same group
    else

      previous = update_previous(previous, 'data', file, i);

      for gi = previous.group.index:numel(subject.(modality)) - 1
        dep_fname = fullfile(pth, subject.(modality)(gi).filename);
        subject.(modality)(end).dependencies.group{end + 1, 1} = dep_fname;
        subject.(modality)(gi).dependencies.group{end + 1, 1} = fullpath_filename;
      end
    end

    % new group
  else
    previous = update_previous(previous, 'group', file, numel(subject.(modality)));
    previous = update_previous(previous, 'data', file, i);

  end

end

function status = same_group(file, previous)

  this_file_group_base = find(file == '_', 1, 'last');
  status = strcmp(previous.group.base, file(1:this_file_group_base));

end

function status = same_data(file, previous)

  status = strncmp(previous.data.base, file, previous.data.len);

end

function previous = update_previous(previous, type, file, idx)
  if strcmp(type, 'data')
    previous.data.len = find(file == '.', 1);
  elseif strcmp(type, 'group')
    previous.group.len = find(file == '_', 1, 'last');
  end
  previous.(type).base = file(1:previous.(type).len);
  previous.(type).index = idx;
end

function structure = manage_tsv(structure, pth, filename, verbose)
  % Returns the content and metadata of a TSV file (if they exist)
  %
  % NOTE: inheritance principle not implemented.
  % Does NOT look for the metadata of a file at higher levels
  %

  tolerant = true;

  ext = bids.internal.file_utils(filename, 'ext');
  tsv_file = bids.internal.file_utils('FPList', ...
                                      pth,  ...
                                      ['^' strrep(filename, ['.' ext], ['\.' ext]) '$']);

  if isempty(tsv_file)
    msg = sprintf('Missing: %s', fullfile(pth, filename));
    bids.internal.error_handling(mfilename, 'tsvMissing', msg, tolerant, verbose);

  else
    structure.content = bids.util.tsvread(tsv_file);

    tsv_file = bids.internal.file_utils('FPList', ...
                                        pth,  ...
                                        ['^' strrep(filename, ['.' ext], '\.json') '$']);
    if ~isempty(tsv_file)
      structure.meta = bids.util.jsondecode(tsv_file);
    end

  end

end

function BIDS = manage_dependencies(BIDS, verbose)
  %
  % Loops over all files and retrieve all files that current file depends on
  %

  tolerant = true;

  file_list = bids.query(BIDS, 'data');

  for iFile = 1:size(file_list, 1)

    info_src = bids.internal.return_file_info(BIDS, file_list{iFile});
    % skip files in the root folder with no sub entity
    if isempty(info_src.sub_idx)
      continue
    end
    file = BIDS.subjects(info_src.sub_idx).(info_src.modality)(info_src.file_idx);
    metadata = bids.internal.get_metadata(file.metafile);

    % If the file A is intended for file B
    %   then we update the dependencies.explicit field structrure of file B
    %   so it contains the fullpath to file A
    %
    % This way when one queries info about B, then it is easy to know what
    % other is present to help with analysis.
    intended = {};
    if isfield(metadata, 'IntendedFor')
      intended = cellstr(metadata.IntendedFor);
    end

    for iIntended = 1:numel(intended)
      dest = fullfile(BIDS.pth, BIDS.subjects(info_src.sub_idx).name, ...
                      intended{iIntended});
      if ~exist(dest, 'file')
        msg = ['IntendedFor file ' dest ' from ' file.filename ' not found'];
        bids.internal.error_handling(mfilename, 'IntendedForMissing', msg, tolerant, verbose);
        continue
      end
      info_dest = bids.internal.return_file_info(BIDS, dest);
      BIDS.subjects(info_dest.sub_idx).(info_dest.modality)(info_dest.file_idx) ...
          .dependencies.explicit{end + 1, 1} = file_list{iFile};
    end

  end

end

function perf = manage_M0(perf, pth, verbose)

  tolerant = true;

  % M0 field is flexible:

  if ~isfield(perf.meta, 'M0Type')

    msg = sprintf('M0Type field missing for %s', perf.filename);
    bids.internal.error_handling(mfilename, 'm0typeMissing', msg, tolerant, verbose);

  else

    m0_type = [];
    m0_explanation = [];
    m0_volume_index = [];
    m0_value = [];
    m0_filename = [];
    m0_sidecar = [];

    switch perf.meta.M0Type

      case 'Separate'
        % the M0 was obtained as a separate scan
        m0_type = 'separate_scan';
        m0_explanation = 'M0 was obtained as a separate scan';

        % M0scan.nii filename
        % assuming the (.nii|.nii.gz) extension choice is the same throughout
        m0_filename = strrep(perf.filename, ...
                             ['_asl' perf.ext], ...
                             ['_m0scan' perf.ext]);

        if ~exist(fullfile(pth, m0_filename), 'file')
          msg = ['Missing: ' m0_filename];
          bids.internal.error_handling(mfilename, 'm0FileMissing', msg, tolerant, verbose);

        else
          % subject.perf(j).m0_filename = m0_filename;
          % -> this is included in the same structure for the m0scan.nii
        end

        % M0 sidecar filename
        m0_sidecar = strrep(perf.filename, ...
                            ['_asl' perf.ext], ...
                            '_m0scan.json');

        if ~exist(fullfile(pth, m0_sidecar), 'file')
          msg = ['Missing: ' m0_sidecar];
          bids.internal.error_handling(mfilename, 'm0JsonMissing', msg, tolerant, verbose);

        else
          % subject.perf(j).m0_json_sidecar_filename = m0_json_sidecar_filename;
          % -> this is included in the same structure for the m0scan.nii
        end

      case 'Included'
        % M0 is one or more image(s) in the *asl.nii[.gz] timeseries
        if ~isfield(perf.dependencies, 'context') || ...
                ~isfield(perf.dependencies.context.content, 'volume_type')
          msg = 'Cannot find M0 volume type in aslcontext';
          bids.internal.error_handling(mfilename, 'm0VolumeTypeMissing', msg, tolerant, verbose);

        else
          m0indices = find(cellfun(@(x) strcmp(x, 'm0scan'), ...
                                   perf.dependencies.context.content.volume_type) == true);

          if isempty(m0indices)
            msg = 'No M0 volume found in aslcontext';
            bids.internal.error_handling(mfilename, 'm0VolumeMissing', msg, tolerant, verbose);

          else
            m0_type = 'within_timeseries';
            m0_explanation = 'M0 is one or more image(s) in the *asl.nii[.gz] timeseries';
            m0_volume_index = m0indices;

          end
        end

      case 'Estimate'
        m0_type = 'single_value';
        m0_explanation = [ ...
                          'this is a single estimated M0 value, ', ...
                          'e.g. when the M0 is obtained from an external scan and/or study'];
        m0_value = perf.meta.M0Estimate;

      case 'Absent'
        m0_type = 'use_control_as_m0';
        m0_explanation = [ ...
                          'M0 is absent, so we can use the (average) control volume ', ...
                          'as pseudo-M0 (if no background suppression was used)'];

        if perf.meta.BackgroundSuppression == true
          msg = 'Caution when using control as M0: background suppression was applied';
          bids.internal.error_handling(mfilename, 'm0BackgroundSuppression', msg, ...
                                       tolerant, ...
                                       verbose);
        end

      otherwise
        msg = ['Unknown M0Type:', perf.meta.M0Type];
        bids.internal.error_handling(mfilename, 'unknownM0Type', msg, tolerant, verbose);

    end

    if ~isempty(m0_type)
      perf.dependencies.m0.type = m0_type;
      perf.dependencies.m0.explanation = m0_explanation;
    end

    if ~isempty(m0_volume_index)
      perf.dependencies.m0.volume_index = m0_volume_index;
    end

    if ~isempty(m0_value)
      perf.dependencies.m0.value = m0_value;
    end

    if ~isempty(m0_filename)
      perf.dependencies.m0.filename = m0_filename;
    end

    if ~isempty(m0_sidecar)
      perf.dependencies.m0.sidecar = m0_sidecar;
    end

  end

end
