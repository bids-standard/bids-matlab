function BIDS = layout(root, tolerant)
  % Parse a directory structure formated according to the BIDS standard
  % FORMAT BIDS = bids.layout(root)
  % root     - directory formated according to BIDS [Default: pwd]
  % tolerant - if set to 0 (default) only files g
  % BIDS     - structure containing the BIDS file layout
  % __________________________________________________________________________
  %
  % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
  %   The brain imaging data structure, a format for organizing and
  %   describing outputs of neuroimaging experiments.
  %   K. J. Gorgolewski et al, Scientific Data, 2016.
  % __________________________________________________________________________

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
      BIDS = root; % or BIDS = bids.layout(root.root);
      return
    else
      error('Invalid syntax.');
    end
  elseif nargin > 2
    error('Too many input arguments.');
  end

  if ~exist('tolerant', 'var')
    tolerant = false;
  end

  % -BIDS structure
  % ==========================================================================

  % BIDS.dir          -- BIDS directory
  % BIDS.description  -- content of dataset_description.json
  % BIDS.sessions     -- cellstr of sessions
  % BIDS.scans        -- for sub-<participant_label>_scans.tsv (should go within subjects)
  % BIDS.sess         -- for sub-<participants_label>_sessions.tsv (should go within subjects)
  % BIDS.participants -- for participants.tsv
  % BIDS.subjects'    -- structure array of subjects

  BIDS = struct( ...
                'dir', root, ...
                'description', struct([]), ...
                'sessions', {{}}, ...
                'scans', struct([]), ...
                'sess', struct([]), ...
                'participants', struct([]), ...
                'subjects', struct([]));

  % -Validation of BIDS root directory
  % ==========================================================================
  if ~exist(BIDS.dir, 'dir')
    error('BIDS directory does not exist: ''%s''', BIDS.dir);

  elseif ~exist(fullfile(BIDS.dir, 'dataset_description.json'), 'file')

    msg = sprintf('BIDS directory not valid: missing dataset_description.json: ''%s''', ...
                  BIDS.dir);

    tolerant_message(tolerant, msg);

  end

  % -Dataset description
  % ==========================================================================
  try
    BIDS.description = bids.util.jsondecode(fullfile(BIDS.dir, 'dataset_description.json'));
  catch err
    msg = sprintf('BIDS dataset description could not be read: %s', err.message);
    tolerant_message(tolerant, msg);
  end

  fields_to_check = {'BIDSVersion', 'Name'};
  for iField = 1:numel(fields_to_check)

    if ~isfield(BIDS.description, fields_to_check{iField})
      msg = sprintf( ...
                    'BIDS dataset description not valid: missing %s field.', ...
                    fields_to_check{iField});
      tolerant_message(tolerant, msg);
    end

  end

  % -Optional directories
  % ==========================================================================
  % [code/]
  % [derivatives/]
  % [stimuli/]
  % [sourcedata/]
  % [phenotype/]

  % -Scans key file
  % ==========================================================================

  % sub-<participant_label>/[ses-<session_label>/]
  %     sub-<participant_label>_scans.tsv

  % See also optional README and CHANGES files

  % -Participant key file
  % ==========================================================================
  p = bids.internal.file_utils('FPList', BIDS.dir, '^participants\.tsv$');
  if ~isempty(p)
    try
      BIDS.participants = bids.util.tsvread(p);
    catch
      msg = ['unable to read ' p];
      tolerant_message(tolerant, msg);
    end
  end
  p = bids.internal.file_utils('FPList', BIDS.dir, '^participants\.json$');
  if ~isempty(p)
    BIDS.participants.meta = bids.util.jsondecode(p);
  end

  % -Sessions file
  % ==========================================================================

  % sub-<participant_label>/[ses-<session_label>/]
  %      sub-<participant_label>[_ses-<session_label>]_sessions.tsv

  % -Tasks: JSON files are accessed through metadata
  % ==========================================================================
  % t = bids.internal.file_utils('FPList',BIDS.dir,...
  %    '^task-.*_(beh|bold|events|channels|physio|stim|meg)\.(json|tsv)$');

  % -Subjects
  % ==========================================================================
  sub = cellstr(bids.internal.file_utils('List', BIDS.dir, 'dir', '^sub-.*$'));
  if isequal(sub, {''})
    error('No subjects found in BIDS directory.');
  end

  for iSub = 1:numel(sub)
    sess = cellstr(bids.internal.file_utils('List', ...
                                            fullfile(BIDS.dir, sub{iSub}), ...
                                            'dir', ...
                                            '^ses-.*$'));

    for iSess = 1:numel(sess)
      if isempty(BIDS.subjects)
        BIDS.subjects = parse_subject(BIDS.dir, sub{iSub}, sess{iSess});
      else
        BIDS.subjects(end + 1) = parse_subject(BIDS.dir, sub{iSub}, sess{iSess});
      end
    end

  end

end

function tolerant_message(tolerant, msg)
  if tolerant
    warning(msg);
  else
    error(msg);
  end
end

% ==========================================================================
% -Parse a subject's directory
% ==========================================================================
function subject = parse_subject(pth, subjname, sesname)

  % For each modality (anat, func, eeg...) all the files from the
  % corresponding directory are listed and their filenames parsed with extra
  % BIDS valid entities listed (e.g. 'acq','ce','rec','fa'...).

  subject.name    = subjname;   % subject name ('sub-<participant_label>')
  subject.path    = fullfile(pth, subjname, sesname); % full path to subject directory
  subject.session = sesname; % session name ('' or 'ses-<label>')
  subject.anat    = struct([]); % anatomy imaging data
  subject.func    = struct([]); % task imaging data
  subject.fmap    = struct([]); % fieldmap data
  subject.beh     = struct([]); % behavioral experiment data
  subject.dwi     = struct([]); % diffusion imaging data
  subject.perf    = struct([]); % ASL perfusion imaging data
  subject.eeg     = struct([]); % EEG data
  subject.meg     = struct([]); % MEG data
  subject.ieeg    = struct([]); % iEEG data
  subject.pet     = struct([]); % PET imaging data

  % use BIDS schema to organizing parsing of subject data
  schema = bids.schema.load_schema();
  modalities = fieldnames(schema.modalities);

  for iModality = 1:numel(modalities)

    datatypes = schema.modalities.(modalities{iModality}).datatypes;

    for iDatatype = 1:numel(datatypes)
      switch datatypes{iDatatype}
        case {'anat', 'beh', 'ieeg'}
          subject = parse_using_schema(subject, datatypes{iDatatype}, schema);
        case 'dwi'
          subject = parse_dwi(subject, schema);
        case {'eeg', 'meg'}
          subject = parse_meeg(subject, datatypes{iDatatype}, schema);
        case 'fmap'
          subject = parse_fmap(subject, schema);
        case 'func'
          subject = parse_func(subject, schema);
        case 'perf'
          subject = parse_perf(subject, schema);
      end
    end

  end

  % not covered by schema... yet
  subject = parse_pet(subject);

end

function subject = parse_using_schema(subject, datatype, schema)

  pth = fullfile(subject.path, datatype);

  if exist(pth, 'dir')

    file_list = return_file_list(datatype, subject);

    for i = 1:numel(file_list)

      subject = bids.internal.append_to_structure(file_list{i}, subject, datatype, schema);

    end

  end

end

function subject = parse_dwi(subject, schema)

  % --------------------------------------------------------------------------
  %  Diffusion imaging data
  % --------------------------------------------------------------------------

  datatype = 'dwi';
  pth = fullfile(subject.path, datatype);

  if exist(pth, 'dir')

    file_list = return_file_list(datatype, subject);

    for i = 1:numel(file_list)

      subject = bids.internal.append_to_structure(file_list{i}, subject, datatype, schema);
      
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

function subject = parse_func(subject, schema)

  % --------------------------------------------------------------------------
  %  Task imaging data
  % --------------------------------------------------------------------------

  datatype = 'func';
  pth = fullfile(subject.path, datatype);

  if exist(pth, 'dir')

    file_list = return_file_list(datatype, subject);

    for i = 1:numel(file_list)

      subject = bids.internal.append_to_structure(file_list{i}, subject, datatype, schema);
      subject.func(end).meta = struct([]); % ?

      % TODO:
      %
      % Events, physiological and other continuous recordings file
      % can also be stored at higher levels (inheritance principle).
      %

      if strcmp(subject.func(end).type, 'events')
        subject.func(end).meta = bids.util.tsvread(fullfile(pth, file_list{i}));
      end

    end

  end
end

function subject = parse_perf(subject, schema)

  % --------------------------------------------------------------------------
  % ASL perfusion imaging data
  % --------------------------------------------------------------------------

  datatype = 'perf';
  pth = fullfile(subject.path, 'perf');

  if exist(pth, 'dir')

    file_list = return_file_list(datatype, subject);

    for i = 1:numel(file_list)

      subject = bids.internal.append_to_structure(file_list{i}, subject, datatype, schema);

    end

    % ASL timeseries NIfTI file
    % ----------------------------------------------------------------------
    labels = regexp(file_list, [ ...
                                '^sub-[a-zA-Z0-9]+' ...              % sub-<participant_label>
                                '_asl\.nii(\.gz)?$'], 'names'); % NIfTI file suffix/extension

    if any(~cellfun(@isempty, labels))

      idx = find(~cellfun(@isempty, labels));

      for i = 1:numel(idx)

        j = idx(i);

        subject.perf(j).meta = [];
        subject.perf(j).dependencies = [];

        subject.perf(j).meta = bids.internal.get_metadata( ...
                                                          fullfile( ...
                                                                   subject.path, ...
                                                                   datatype, ...
                                                                   file_list{j}));

        subject.perf(j) = manage_aslcontext(subject.perf(j), pth);

        subject.perf(j) = manage_asllabeling(subject.perf(j), pth);

        subject.perf(j) = manage_M0(subject.perf(j), pth);

      end

    end

    % -M0scan NIfTI file
    % ---------------------------------------------------------------------
    labels = regexp(file_list, [ ...
                                '^sub-[a-zA-Z0-9]+' ...              % sub-<participant_label>
                                '_m0scan\.nii(\.gz)?$'], 'names'); % NIfTI file suffix/extension

    if any(~cellfun(@isempty, labels))
      idx = find(~cellfun(@isempty, labels));
      for i = 1:numel(idx)

        j = idx(i);

        subject.perf(j).intended_for = [];

        subject.perf(j).meta = bids.internal.get_metadata( ...
                                                          fullfile( ...
                                                                   subject.path, ...
                                                                   datatype, ...
                                                                   file_list{j}));

        subject.perf(j) = manage_intended_for(subject.perf(j), subject, pth);

      end

    end

  end % if exist(pth, 'dir')

end

function perf = manage_aslcontext(perf, pth)

  % ASLCONTEXT-sidecar metadata (REQUIRED)
  % ---------------------------
  metafile = fullfile(pth, strrep(perf.filename, ...
                                  ['_asl' perf.ext], ...
                                  '_aslcontext.tsv'));

  if exist(metafile, 'file')
    [~, Ffile] = fileparts(metafile);
    perf.dependencies.context.sidecar = [Ffile '.tsv'];
    perf.dependencies.context.content = bids.util.tsvread(metafile);

  else
    warning(['Missing: ' metafile]);

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
    perf.dependencies.labeling_image = [Ffile '.jpg'];

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
        warning(['Unknown M0Type:', ...
                 perf.meta.M0Type, ...
                 ' in ', ...
                 perf.json_sidecar_filename]);
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

function subject = parse_fmap(subject, schema)

  datatype = 'fmap';
  pth = fullfile(subject.path, datatype);

  if exist(pth, 'dir')

    file_list = return_file_list(datatype, subject);

    for i = 1:numel(file_list)

      subject = bids.internal.append_to_structure(file_list{i}, subject, datatype, schema);

      subject.fmap(i).meta = bids.internal.get_metadata( ...
                                                        fullfile( ...
                                                                 subject.path, ...
                                                                 datatype, ...
                                                                 file_list{i}));
      %       subject.perf(i).intended_for = [];
      %       subject.fmap(i) = manage_intended_for(subject.fmap(i), subject, pth);

      switch subject.fmap(i).type

        % -A single, real fieldmap image
        case {'fieldmap', 'magnitude'}
          subject.fmap(i).dependencies.magnitude = strrep(file_list{idx(i)}, ...
                                                          '_fieldmap.nii', ...
                                                          '_magnitude.nii');

          % -Phase difference image and at least one magnitude image
        case {'phasediff'}
          subject.fmap(i).dependencies.magnitude = { ...
                                                    strrep(file_list{i}, ...
                                                           '_phasediff.nii', ...
                                                           '_magnitude1.nii'), ...
                                                    strrep(file_list{i}, ...
                                                           '_phasediff.nii', ...
                                                           '_magnitude2.nii')}; % optional

          % -Two phase images and two magnitude images
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

function subject = parse_meeg(subject, datatype, schema)

  pth = fullfile(subject.path, datatype);

  if exist(pth, 'dir')

    file_list = return_file_list(datatype, subject);

    for i = 1:numel(file_list)

      subject = bids.internal.append_to_structure(file_list{i}, subject, datatype, schema);

      switch subject.(datatype)(end).type

        case {'events', 'channels', 'electrodes'}  %
          % TODO: events / channels file can also be stored
          % at higher levels (inheritance principle)
          %
          subject.(datatype)(end).meta = bids.util.tsvread(fullfile(pth, file_list{i}));

        case {'photo', 'coordsystem'}

      end

    end

  end

end

function subject = parse_pet(subject)
  % --------------------------------------------------------------------------
  % -Positron Emission Tomography imaging data
  % --------------------------------------------------------------------------
  pth = fullfile(subject.path, 'pet');

  if exist(pth, 'dir')

    entities = return_entities('pet');

    file_list = return_file_list('pet', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'pet');

    end
  end
end

% --------------------------------------------------------------------------
%                            HELPER FUNCTIONS
% --------------------------------------------------------------------------

function subject = append_to_structure(file, entities, subject, modality)

  p = bids.internal.parse_filename(file, entities);
  subject.(modality) = [subject.(modality) p];

end

function f = convert_to_cell(f)
  if isempty(f)
    f = {};
  else
    f = cellstr(f);
  end
end

function entities = return_entities(modality)

  switch modality

    case 'pet'
      entities = {'sub', 'ses', 'task', 'acq', 'rec', 'run'};

  end
end

function file_list = return_file_list(modality, subject)

  % We list anything but json files

  % TODO
  % it should be possible to create some of those patterns for the regexp
  % based on some of the required entities written down in the schema

  % jn to omit json but not .pos file for headshape.pos
  pattern = '_([a-zA-Z0-9]+){1}\\..*[^jn]';

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
