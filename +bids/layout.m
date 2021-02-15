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

  % -Validate input arguments
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

  % BIDS structure
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

  % Optional directories
  % ==========================================================================
  % [code/] - ignore
  % [derivatives/]
  % [stimuli/] - ingore
  % [sourcedata/] - ignore
  % [phenotype/]

  BIDS.participants = [];
  BIDS.participants = manage_tsv(BIDS.participants, BIDS.dir, 'participants.tsv');

  % Subjects
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
        case {'anat', 'func', 'beh', 'meg', 'eeg', 'ieeg', 'pet'}
          subject = parse_using_schema(subject, modalities{iModality}, schema);
        case 'dwi'
          subject = parse_dwi(subject, schema);
        case 'fmap'
          subject = parse_fmap(subject, schema);
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

      subject = bids.internal.append_to_layout(file_list{i}, subject, modality, schema);

      if ~isempty(subject.(modality)) && strcmp(subject.(modality)(end).ext, '.tsv')
        % events
        % stim
        % channels
        % electrodes
        %
        % does not cover physio.tsv.gz or stim.tsv.gz

        subject.(modality)(end).content = [];
        subject.(modality)(end).meta = [];

        subject.(modality)(end) = manage_tsv( ...
                                             subject.(modality)(end), ...
                                             pth, ...
                                             subject.(modality)(end).filename);

      end

      % case {'photo', 'coordsystem'}

    end

  end

end

function subject = parse_dwi(subject, schema)

  % --------------------------------------------------------------------------
  %  Diffusion imaging data
  % --------------------------------------------------------------------------

  modality = 'dwi';
  pth = fullfile(subject.path, modality);

  if exist(pth, 'dir')

    subject = bids.internal.add_missing_field(subject, modality);

    file_list = return_file_list(modality, subject, schema);

    for i = 1:numel(file_list)

      subject = bids.internal.append_to_layout(file_list{i}, subject, modality, schema);

      % bval & bvec file
      % ------------------------------------------------------------------
      % TODO: they can also be stored at higher levels (inheritance principle)
      bvalfile = bids.internal.get_metadata(file_list{i}, '^.*%s\\.bval$');
      if isfield(bvalfile, 'filename')
        subject.dwi(end).bval = bids.util.tsvread(bvalfile.filename);
      end

      bvecfile = bids.internal.get_metadata(file_list{i}, '^.*%s\\.bvec$');
      if isfield(bvalfile, 'filename')
        subject.dwi(end).bvec = bids.util.tsvread(bvecfile.filename);
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

      subject = bids.internal.append_to_layout(file_list{i}, subject, modality, schema);

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

        case 'm0scan'

          subject.perf(i).intended_for = [];

          subject.perf(i).meta = bids.internal.get_metadata( ...
                                                            fullfile( ...
                                                                     subject.path, ...
                                                                     modality, ...
                                                                     file_list{i}));

          subject.perf(i) = manage_intended_for(subject.perf(i), subject, pth);

      end

    end

  end

end

function subject = parse_fmap(subject, schema)

  modality = 'fmap';
  pth = fullfile(subject.path, modality);

  if exist(pth, 'dir')

    subject = bids.internal.add_missing_field(subject, modality);

    file_list = return_file_list(modality, subject, schema);

    for i = 1:numel(file_list)

      subject = bids.internal.append_to_layout(file_list{i}, subject, modality, schema);

      subject.fmap(i).meta = bids.internal.get_metadata( ...
                                                        fullfile( ...
                                                                 subject.path, ...
                                                                 modality, ...
                                                                 file_list{i}));
      %       subject.perf(i).intended_for = [];
      %       subject.fmap(i) = manage_intended_for(subject.fmap(i), subject, pth);

      switch subject.fmap(i).suffix

        % -A single, real fieldmap image
        case {'fieldmap', 'magnitude'}
          subject.fmap(i).dependencies.magnitude = strrep(file_list{idx(i)}, ...
                                                          '_fieldmap.nii', ...
                                                          '_magnitude.nii');

          % Phase difference image and at least one magnitude image
        case {'phasediff'}
          subject.fmap(i).dependencies.magnitude = { ...
                                                    strrep(file_list{i}, ...
                                                           '_phasediff.nii', ...
                                                           '_magnitude1.nii'), ...
                                                    strrep(file_list{i}, ...
                                                           '_phasediff.nii', ...
                                                           '_magnitude2.nii')}; % optional

          % Two phase images and two magnitude images
        case {'phase1', 'phase2'}
          subject.fmap(i).dependencies.magnitude = { ...
                                                    strrep(file_list{i}, ...
                                                           '_phase1.nii', ...
                                                           '_magnitude1.nii'), ...
                                                    strrep(file_list{i}, ...
                                                           '_phase1.nii', ...
                                                           '_magnitude2.nii')};

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

  p = bids.internal.file_utils('FPList', pth,  ['^' strrep(filename, '.tsv', '\.tsv') '$']);

  if isempty(p)
    warning('Missing: %s', fullfile(pth, filename));

  else
    structure.content = bids.util.tsvread(p);

    p = bids.internal.file_utils('FPList', pth,  ['^' strrep(filename, '.tsv', '\.json') '$']);
    if ~isempty(p)
      structure.meta = bids.util.jsondecode(p);
    end

  end

end

function structure = manage_intended_for(structure, subject, pth)

  if isempty(structure.meta)
    return

  else

    % Get all NIfTIs that this m0scan is intended for
    path_intended_for = {};
    if ~isfield(structure.meta, 'IntendedFor')
      warning('Missing field IntendedFor for %s', structure.filename);

    elseif ischar(structure.meta.IntendedFor)
      path_intended_for{1} = structure.meta.IntendedFor;

    elseif isstruct(structure.meta.IntendedFor)
      for iPath = 1:length(structure.meta.IntendedFor)
        path_intended_for{iPath} = structure.meta.IntendedFor(iPath); %#ok<*AGROW>
      end

    end

    for iPath = 1:length(path_intended_for)
      % check if this NIfTI is not missing
      if ~exist(fullfile(fileparts(pth), path_intended_for{iPath}), 'file')
        warning(['Missing: ' fullfile(fileparts(pth), path_intended_for{iPath})]);

      else
        % also check that this NIfTI aims to the same m0scan
        [~, path2check, ext2check] = fileparts(path_intended_for{iPath});
        filename_found = max(arrayfun(@(x) strcmp(x.filename, ...
                                                  [path2check ext2check]), ...
                                      subject.perf));
        if ~filename_found
          warning(['Did not find NIfTI for which is intended: ' structure.filename]);

        else
          structure.intended_for = path_intended_for{iPath};

        end
      end
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
        m0_value = perf.meta.M0;

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
