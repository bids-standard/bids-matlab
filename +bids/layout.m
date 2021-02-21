function BIDS = layout(root, use_schema)
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
  %                    in that folder willl be used for parsing.
  % :type  use_schema: boolean
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
  % Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  %% Validate input arguments
  % ==========================================================================
  if ~nargin
    root = pwd;

  elseif nargin == 1

    if ischar(root)
      root = bids.internal.file_utils(root, 'CPath');

    elseif isstruct(root)
      BIDS = root; % for bids.query
      return

    else
      error('Invalid syntax.');

    end

  elseif nargin > 2
    error('Too many input arguments.');

  end

  if ~exist('use_schema', 'var')
    use_schema = true;
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
                'dir', root, ...
                'description', struct([]), ...
                'sessions', {{}}, ...
                'participants', struct([]), ...
                'subjects', struct([]));

  BIDS = validate_description(BIDS, use_schema);

  %% Optional directories
  % ==========================================================================
  % [code/] - ignore
  % [derivatives/]
  % [stimuli/] - ingore
  % [sourcedata/] - ignore
  % [phenotype/]

  BIDS.participants = [];
  BIDS.participants = manage_tsv(BIDS.participants, BIDS.dir, 'participants.tsv');

  %% Subjects
  % ==========================================================================
  subjects = cellstr(bids.internal.file_utils('List', BIDS.dir, 'dir', '^sub-.*$'));
  if isequal(subjects, {''})
    error('No subjects found in BIDS directory.');
  end

  schema = bids.schema.load_schema(use_schema);

  for iSub = 1:numel(subjects)
    sessions = cellstr(bids.internal.file_utils('List', ...
                                                fullfile(BIDS.dir, subjects{iSub}), ...
                                                'dir', ...
                                                '^ses-.*$'));

    for iSess = 1:numel(sessions)
      if isempty(BIDS.subjects)
        BIDS.subjects = parse_subject(BIDS.dir, subjects{iSub}, sessions{iSess}, schema);
      else
        new_subject = parse_subject(BIDS.dir, subjects{iSub}, sessions{iSess}, schema);

        [BIDS.subjects, new_subject] = bids.internal.match_structure_fields(BIDS.subjects, ...
                                                                            new_subject);
        % TODO: this can be added to "match_structure_fields"
        BIDS.subjects(end + 1) = new_subject;

      end
    end

  end

  %% Dependencies
  % ==========================================================================

  % BIDS = manage_intended_for(BIDS);
  BIDS = manage_dependencies(BIDS);

end

function subject = parse_subject(pth, subjname, sesname, schema)
  %
  % Parse a subject's directory
  %
  % For each modality (anat, func, eeg...) all the files from the
  % corresponding directory are listed and their filenames parsed with
  % BIDS valid entities as listed in the schema (if the schema is not empty).

  subject.name    = subjname;   % subject name ('sub-<participant_label>')
  subject.path    = fullfile(pth, subjname, sesname); % full path to subject directory
  subject.session = sesname;    % session name ('' or 'ses-<label>')
  subject.scans   = struct([]); % for sub-<participant_label>_scans.tsv
  subject.sess    = struct([]); % for sub-<participants_label>_sessions.tsv

  modality_groups = bids.schema.return_modality_groups(schema);

  for iGroup = 1:numel(modality_groups)

    modalities = bids.schema.return_modalities(subject, schema, modality_groups{iGroup});

    % if we go schema-less, we pass an empty schema to all the parsing functions
    % so the parsing is unconstrained
    for iModality = 1:numel(modalities)
      switch modalities{iModality}
        case {'anat', 'func', 'beh', 'meg', 'eeg', 'ieeg', 'pet', 'fmap', 'dwi'}
          subject = parse_using_schema(subject, modalities{iModality}, schema);
        case 'perf'
          subject = parse_perf(subject, schema);
        otherwise
          % in case we are going schemaless
          % and the modality is not one of the usual suspect
          subject.(modalities{iModality}) = struct([]);
          subject = parse_using_schema(subject, modalities{iModality}, []);
      end
    end

  end

end

function subject = parse_using_schema(subject, modality, schema)

  pth = fullfile(subject.path, modality);

  if exist(pth, 'dir')

    subject = bids.internal.add_missing_field(subject, modality);

    file_list = return_file_list(modality, subject, schema);

    for i = 1:numel(file_list)

      fullpath_filename = fullfile(pth, file_list{i});
      subject = bids.internal.append_to_layout(file_list{i}, subject, modality, schema);
      subject.(modality)(end).metafile = bids.internal.get_meta_list(fullpath_filename);
      subject.(modality)(end).dependencies.explicit = {};
      subject.(modality)(end).dependencies.data = {};
      subject.(modality)(end).dependencies.group = {};

      ext = subject.(modality)(end).ext;
      suffix = subject.(modality)(end).suffix;
      search = strrep(file_list{i}, ['_' suffix ext], '_[a-zA-Z0-9.]+$');
      candidates = bids.internal.file_utils('List', pth, ['^' search '$']);
      candidates = cellstr(candidates);
      for ii = 1:numel(candidates)
        if strcmp(candidates{ii}, file_list{i})
          continue;
        end
        if endsWith(candidates{ii}, '.json')
          continue
        end
        match = regexp(candidates{ii}, ['_' suffix '\..*$'], 'match');
        if isempty(match) % different suffix
          subject.(modality)(end).dependencies.group{end+1} = fullfile(pth, candidates{ii});
        else  % same suffix
          subject.(modality)(end).dependencies.data{end+1} = fullfile(pth, candidates{ii});
        end
      end
    end

  end

end

function subject = parse_perf(subject, schema)

  % --------------------------------------------------------------------------
  % ASL perfusion imaging data
  % --------------------------------------------------------------------------

  modality = 'perf';
  pth = fullfile(subject.path, 'perf');

  if exist(pth, 'dir')

    subject = bids.internal.add_missing_field(subject, modality);

    file_list = return_file_list(modality, subject, schema);

    for i = 1:numel(file_list)

      fullpath_filename = fullfile(pth, file_list{i});
      subject = bids.internal.append_to_layout(file_list{i}, subject, modality, schema);
      subject.(modality)(end).metafile = bids.internal.get_meta_list(fullpath_filename);
      subject.(modality)(end).dependencies.explicit = {};
      subject.(modality)(end).dependencies.data = {};
      subject.(modality)(end).dependencies.group = {};

      ext = subject.(modality)(end).ext;
      suffix = subject.(modality)(end).suffix;
      search = strrep(file_list{i}, ['_' suffix ext], '_[a-zA-Z0-9.]+$');
      candidates = bids.internal.file_utils('List', pth, ['^' search '$']);
      candidates = cellstr(candidates);
      for ii = 1:numel(candidates)
        if strcmp(candidates{ii}, file_list{i})
          continue;
        end
        if endsWith(candidates{ii}, '.json')
          continue
        end
        match = regexp(candidates{ii}, ['_' suffix '\..*$'], 'match');
        if isempty(match) % different suffix
          subject.(modality)(end).dependencies.group{end+1} = fullfile(pth, candidates{ii});
        else  % same suffix
          subject.(modality)(end).dependencies.data{end+1} = fullfile(pth, candidates{ii});
        end
      end

      switch subject.perf(i).suffix

        case 'asl'

          subject.perf(i).meta = [];
          subject.perf(i).dependencies = [];

          subject.perf(i).meta = bids.internal.get_metadata( ...
                                                            fullfile( ...
                                                                     subject.path, ...
                                                                     modality, ...
                                                                     file_list{i}));

          aslcontext_file = strrep(subject.perf(i).filename, ...
                                   ['_asl' subject.perf(i).ext], ...
                                   '_aslcontext.tsv');
          subject.perf(i).dependencies.context = manage_tsv( ...
                                                            struct('content', [], 'meta', []), ...
                                                            pth, ...
                                                            aslcontext_file);

          subject.perf(i) = manage_asllabeling(subject.perf(i), pth);

          subject.perf(i) = manage_M0(subject.perf(i), pth);

      end

    end

  end

end

% --------------------------------------------------------------------------
%                            HELPER FUNCTIONS
% --------------------------------------------------------------------------

function BIDS = validate_description(BIDS, use_schema)

  if ~exist(fullfile(BIDS.dir, 'dataset_description.json'), 'file')

    msg = sprintf('BIDS directory not valid: missing dataset_description.json: ''%s''', ...
                  BIDS.dir);

    tolerant_message(use_schema, msg);

  end
  try
    BIDS.description = bids.util.jsondecode(fullfile(BIDS.dir, 'dataset_description.json'));
  catch err
    msg = sprintf('BIDS dataset description could not be read: %s', err.message);
    tolerant_message(use_schema, msg);
  end

  fields_to_check = {'BIDSVersion', 'Name'};
  for iField = 1:numel(fields_to_check)

    if ~isfield(BIDS.description, fields_to_check{iField})
      msg = sprintf( ...
                    'BIDS dataset description not valid: missing %s field.', ...
                    fields_to_check{iField});
      tolerant_message(use_schema, msg);
    end

    % TODO
    % Add warning if bids version does not match schema version

  end

end

function tolerant_message(use_schema, msg)
  if use_schema
    error(msg);
  else
    warning(msg);
  end
end

function f = convert_to_cell(f)
  if isempty(f)
    f = {};
  else
    f = cellstr(f);
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
  if isempty(schema)
    pattern = '_([a-zA-Z0-9]+){1}\\..*';
  end

  pth = fullfile(subject.path, modality);

  [file_list, d] = bids.internal.file_utils('List', ...
                                            pth, ...
                                            sprintf(['^%s.*' pattern '$'], ...
                                                    subject.name));

  file_list = convert_to_cell(file_list);

  if strcmp(modality, 'meg') && ~isempty(d)
    for i = 1:size(d, 1)
      file_list{end + 1, 1} = d(i, :);
    end
  end

end

function structure = manage_tsv(structure, pth, filename)

  ext = bids.internal.file_utils(filename, 'ext');
  tsv_file = bids.internal.file_utils('FPList', ...
                                      pth,  ...
                                      ['^' strrep(filename, ['.' ext], ['\.' ext]) '$']);

  if isempty(tsv_file)
    warning('Missing: %s', fullfile(pth, filename));

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

function BIDS = manage_dependencies(BIDS)
  % Loops over all files and retrieve all files that current file depends on
  file_list = bids.query(BIDS, 'data');
  for iFile = 1:size(file_list, 1)
    info_src = bids.internal.return_file_info(BIDS, file_list{iFile});
    file = BIDS.subjects(info_src.sub_idx).(info_src.modality)(info_src.file_idx);
    metadata = bids.internal.get_metadata(file.metafile);

    intended = {};
    if isfield(metadata, 'IntendedFor')
      intended = cellstr(metadata.IntendedFor);
    end

    for iIntended = 1:numel(intended)
      dest = fullfile(BIDS.dir, BIDS.subjects(info_src.sub_idx).name, ...
                      intended{iIntended});
      if ~exist(dest, 'file')
        warning(['IntendedFor file ' dest ' from ' file.filename ' not found']);
        continue;
      end
      info_dest = bids.internal.return_file_info(BIDS, dest);
      BIDS.subjects(info_dest.sub_idx).(info_dest.modality)(info_dest.file_idx)...
          .dependencies.explicit{end+1} = file_list{iFile};
    end

  end
end

function BIDS = manage_intended_for(BIDS)

  % Loops through all the files with potential ``intentedFor`` metadata
  % and creates an ``intended_for`` field with the fullpath list of all the target files
  % it is intended for that exist.
  %
  % Also update the structure of each target file with an ``informed_by`` field

  suffix_with_intended_for = { ...
                              'phasediff'; ...
                              'phase1'; ...
                              'phase2'; ...
                              'fieldmap'; ...
                              'epi'; ...
                              'm0scan'; ...
                              'coordsystem'};

  for iSuffix = 1:numel(suffix_with_intended_for)
    file_list = bids.query(BIDS, 'data', 'suffix', suffix_with_intended_for(iSuffix));

    for iFile = 1:size(file_list, 1)

      info_src = bids.internal.return_file_info(BIDS, file_list{iFile});

      [metadata, intended_for] = check_intended_for_exist(BIDS.subjects(info_src.sub_idx), ...
                                                          fullfile( ...
                                                                   info_src.path, ...
                                                                   info_src.modality, ...
                                                                   info_src.filename));

      BIDS.subjects(info_src.sub_idx).(info_src.modality)(info_src.file_idx).meta = metadata;
      BIDS.subjects(info_src.sub_idx).(info_src.modality)(info_src.file_idx).intended_for = ...
          intended_for;

      % update "dependency" field of target file
      informed_by = [];
      for iTargetFile = 1:size(intended_for, 1)

        info_tgt = bids.internal.return_file_info(BIDS, intended_for{iTargetFile});

        % TODO: this should probably check that the informed_by field does not
        % already exist in the structure
        % TODO: This assumes that a file will only be informed by a single file from
        % this moodality
        informed_by.(info_src.modality) = file_list{iFile};
        BIDS.subjects(info_tgt.sub_idx).(info_tgt.modality)(info_tgt.file_idx).informed_by = ...
            informed_by;
      end

    end

  end

end

function [metadata, intended_for] = check_intended_for_exist(subject, filename)

  metadata =  bids.internal.get_metadata(filename);

  intended_for = {};

  if isempty(metadata) || ~isfield(metadata, 'IntendedFor')
    warning('Missing field IntendedFor for %s', filename);
    return

  else

    path_intended_for = {};

    if ischar(metadata.IntendedFor)
      path_intended_for{1, 1} = metadata.IntendedFor;

    elseif isstruct(metadata.IntendedFor)
      for iPath = 1:length(metadata.IntendedFor)
        path_intended_for{iPath, 1} = metadata.IntendedFor(iPath); %#ok<*AGROW>
      end

    end
  end

  % get "subject path" without the session folder (if it exists)
  subject_path = subject.path;
  tmp = bids.internal.file_utils(subject_path, 'filename');
  if strcmp(tmp(1:3), 'ses')
    subject_path = bids.internal.file_utils(subject_path, 'path');
  end

  for iPath = 1:size(path_intended_for, 1)

    % create a fullname path for current operating system
    fullpath_filename = fullfile(subject_path, ...
                                 strrep(path_intended_for{iPath}, '/', filesep));

    % check if this file is missing
    if ~exist(fullpath_filename, 'file')
      warning(['Missing: ' fullpath_filename]);

    else
      intended_for{end + 1, 1} = fullpath_filename;

    end
  end

end

function perf = manage_asllabeling(perf, pth)
  % labeling image metadata (OPTIONAL)
  % ---------------------------
  metafile = fullfile(pth, strrep(perf.filename, ...
                                  ['_asl' perf.ext], ...
                                  '_asllabeling.jpg'));

  if exist(metafile, 'file')
    [~, Ffile] = fileparts(metafile);
    perf.dependencies.labeling_image.filename = [Ffile '.jpg'];

  end

end

function perf = manage_M0(perf, pth)

  % M0 field is flexible:

  if ~isfield(perf.meta, 'M0Type')
    warning('M0Type field missing for %s', perf.filename);

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
          warning(['Missing: ' m0_filename]);
        else
          % subject.perf(j).m0_filename = m0_filename;
          % -> this is included in the same structure for the m0scan.nii
        end

        % M0 sidecar filename
        m0_sidecar = strrep(perf.filename, ...
                            ['_asl' perf.ext], ...
                            '_m0scan.json');

        if ~exist(fullfile(pth, m0_sidecar), 'file')
          warning(['Missing: ' m0_sidecar]);

        else
          % subject.perf(j).m0_json_sidecar_filename = m0_json_sidecar_filename;
          % -> this is included in the same structure for the m0scan.nii
        end

      case 'Included'
        % M0 is one or more image(s) in the *asl.nii[.gz] timeseries
        if ~isfield(perf.dependencies, 'context') || ...
                ~isfield(perf.dependencies.context.content, 'volume_type')
          warning('Cannot find M0 volume in aslcontext, context-information missing');

        else
          m0indices = find(cellfun(@(x) strcmp(x, 'm0scan'), ...
                                   perf.dependencies.context.content.volume_type) == true);

          if isempty(m0indices)
            warning('No M0 volume found in aslcontext');

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
          warning('Caution when using control as M0, background suppression was applied');
        end

      otherwise
        warning(['Unknown M0Type:', perf.meta.M0Type]);

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
