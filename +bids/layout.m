function BIDS = layout(root, use_schema, index_derivatives, tolerant, verbose)
  %
  % Parse a directory structure formated according to the BIDS standard
  %
  % USAGE::
  %
  %   BIDS = bids.layout(root = pwd, use_schema = false)
  %
  % :param root:       directory of the dataset formated according to BIDS [default: ``pwd``]
  % :type  root:       string
  % :param use_schema: If set to ``true`` (default), the parsing of the dataset
  %                    will follow the bids-schema provided with bids-matlab.
  %                    If set to ``false`` files just have to be of the form
  %                    ``sub-label_[entity-label]_suffix.ext`` to be parsed.
  %                    If a folder path is provided, then the schema contained
  %                    in that folder will be used for parsing.
  % :type  use_schema: boolean
  %
  %
  % (C) Copyright 2016-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  %% Validate input arguments
  % ==========================================================================
  if ~nargin
    root = pwd;

  elseif nargin > 0

    if ischar(root)
      root = bids.internal.file_utils(root, 'CPath');

    elseif isstruct(root)
      BIDS = root; % for bids.query
      return

    else
      error('Invalid syntax.');

    end

  end

  if ~exist('tolerant', 'var')
    tolerant = true;
  end

  if ~exist('verbose', 'var')
    verbose = false;
  end

  if ~exist('use_schema', 'var')
    use_schema = true;
  end

  if ~exist('index_derivatives', 'var')
    index_derivatives = false;
  end

  if ~exist(root, 'dir')
    error('BIDS directory does not exist: ''%s''', root);
  end

  %% BIDS structure
  % ==========================================================================

  % BIDS.dir          -- BIDS directory
  % BIDS.description  -- content of dataset_description.json
  % BIDS.sessions     -- cellstr of sessions
  % BIDS.participants -- for participants.tsv
  % BIDS.subjects'    -- structure array of subjects

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

  %% Subjects
  % ==========================================================================
  subjects = cellstr(bids.internal.file_utils('List', BIDS.pth, 'dir', '^sub-.*$'));
  if isequal(subjects, {''})
    error('No subjects found in BIDS directory.');
  end

  schema = bids.schema();
  schema = schema.load(use_schema);
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

  %% Dependencies
  % ==========================================================================

  BIDS = manage_dependencies(BIDS, verbose);

  %% Derivatives folder
  % ==========================================================================
  if index_derivatives && exist(fullfile(BIDS.pth, 'derivatives'), 'dir')

    deriv_folders = cellstr(bids.internal.file_utils('List', ...
                                                     fullfile(BIDS.pth, 'derivatives'), ...
                                                     'dir', ...
                                                     '.*'));

    for iDir = 1:numel(deriv_folders)
      BIDS.derivatives.(deriv_folders{iDir}) = bids.layout( ...
                                                           fullfile(BIDS.pth, ...
                                                                    'derivatives', ...
                                                                    deriv_folders{iDir}), ...
                                                           false, ...
                                                           index_derivatives, ...
                                                           true, ...
                                                           verbose);
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
        case {'anat', 'func', 'beh', 'meg', 'eeg', 'ieeg', 'pet', 'fmap', 'dwi', 'perf'}
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
    dep_prev_files = struct( ...
                            'index_group', 0, ...
                            'group_base',  '', ...
                            'group_len', 1, ...
                            'index_data', 0, ...
                            'data_base', '', ...
                            'data_len', 1);

    for iFile = 1:size(file_list, 1)

      [subject, parsing] = bids.internal.append_to_layout(file_list{iFile}, ...
                                                          subject, ...
                                                          modality, ...
                                                          schema);

      if ~isempty(parsing)

        [subject, dep_prev_files] = index_dependencies(subject, ...
                                                       modality, ...
                                                       file_list{iFile}, ...
                                                       iFile, ...
                                                       dep_prev_files);

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

% --------------------------------------------------------------------------
%                            HELPER FUNCTIONS
% --------------------------------------------------------------------------

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

  % We list anything but json files

  % TODO
  % it should be possible to create some of those patterns for the regexp
  % based on some of the required entities written down in the schema

  % TODO
  % this does not cover coordsystem.json

  % jn to omit json but not .pos file for headshape.pos
  pattern = '_([a-zA-Z0-9]+){1}\\..*[^jn]';
  prefix = '';
  if isempty(schema.content)
    pattern = '_([a-zA-Z0-9]+){1}\\..*';
    prefix = '([a-zA-Z0-9]*)';
  end

  pth = fullfile(subject.path, modality);

  [file_list, d] = bids.internal.file_utils('List', ...
                                            pth, ...
                                            sprintf(['^' prefix '%s.*' pattern '$'], ...
                                                    subject.name));

  file_list = convert_to_cell(file_list);

  if strcmp(modality, 'meg') && ~isempty(d)
    for i = 1:size(d, 1)
      file_list{end + 1, 1} = d(i, :); %#ok<*AGROW>
    end
  end

end

function [subject, dep_prev_files] = index_dependencies(subject, modality, file, i, dep_prev_files)
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

  if ~isfield(subject.(modality)(end), 'dependencies') || ...
          isempty(subject.(modality)(end).dependencies)
    subject.(modality)(end).dependencies.explicit = {};
    subject.(modality)(end).dependencies.data = {};
    subject.(modality)(end).dependencies.group = {};
  end

  if strncmp(dep_prev_files.data_base, file, dep_prev_files.data_len)

    %     subject.(modality)(end + 1, 1) = subject.(modality)(end, 1);
    %     subject.(modality)(end, 1).ext = file(dep_prev_files.data_len:end);
    %     subject.(modality)(end, 1).filename = file;

    dep_fname = fullfile(pth, subject.(modality)(end - 1, 1).filename);
    subject.(modality)(end).dependencies.data{end + 1} = dep_fname;

  else
    subject.(modality)(end).metafile = bids.internal.get_meta_list(fullpath_filename);

  end

  % Checking dependencies
  if strncmp(dep_prev_files.group_base, file, dep_prev_files.group_len)
    if strncmp(dep_prev_files.data_base, file, dep_prev_files.data_len)
      % same data
      for di = dep_prev_files.index_data:i - 1
        subject.(modality)(di).dependencies.data{end + 1} = fullpath_filename;
      end
    else
      % not same data but same group
      dep_prev_files.index_data = i;
      dep_prev_files.data_len = find(file == '.', 1);
      dep_prev_files.data_base = file(1:dep_prev_files.data_len);

      for gi = dep_prev_files.index_group:i
        dep_fname = fullfile(pth, subject.(modality)(gi).filename);
        subject.(modality)(end).dependencies.group{end + 1} = dep_fname;
        subject.(modality)(gi).dependencies.group{end + 1} = fullpath_filename;
      end
    end

    % new group
  else
    dep_prev_files.index_group = i;
    dep_prev_files.group_len = find(file == '_', 1, 'last');
    dep_prev_files.group_base = file(1:dep_prev_files.group_len);

    dep_prev_files.index_data = i;
    dep_prev_files.data_len = find(file == '.', 1);
    dep_prev_files.data_base = file(1:dep_prev_files.data_len);
  end

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
