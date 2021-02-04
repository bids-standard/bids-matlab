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
        case 'anat'
          subject = parse_anat(subject);
        case 'beh'
          subject = parse_beh(subject);
        case 'dwi'
          subject = parse_dwi(subject);
        case 'eeg'
          subject = parse_eeg(subject);
        case 'fmap'
          subject = parse_fmap(subject);
        case 'func'
          subject = parse_func(subject);
        case 'ieeg'
          subject = parse_ieeg(subject);
        case 'meg'
          subject = parse_meg(subject);
        case 'perf'
      end
    end

  end

  % not covered by schema... yet
  subject = parse_pet(subject);

end

function subject = parse_anat(subject)

  datatype = 'anat';

  % --------------------------------------------------------------------------
  % -Anatomy imaging data
  % --------------------------------------------------------------------------
  pth = fullfile(subject.path, datatype);

  if exist(pth, 'dir')

    file_list = return_file_list(datatype, subject);

    for i = 1:numel(file_list)

      subject = bids.internal.append_to_structure(file_list{i}, subject, datatype);

    end

  end

end

function subject = parse_func(subject)

  % --------------------------------------------------------------------------
  % -Task imaging data
  % --------------------------------------------------------------------------
  pth = fullfile(subject.path, 'func');

  if exist(pth, 'dir')

    entities = return_entities('func');

    file_list = return_file_list('func', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'func');
      subject.func(end).meta = struct([]); % ?

    end

    file_list = return_event_file_list('func', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'func');

      subject.func(end).meta = bids.util.tsvread(fullfile(pth, file_list{i})); % ?

    end

    file_list = return_physio_stim_file_list('func', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'func');

      subject.func(end).meta = struct([]); % ?

    end
  end
end

function subject = parse_fmap(subject)
  %
  % TODO:
  %
  % 20210114 - From Remi:
  % For other modalities, metadata are fetched upon query.
  % It is unclear why we do it differently for fmaps

  % --------------------------------------------------------------------------
  % -Fieldmap data
  % --------------------------------------------------------------------------
  pth = fullfile(subject.path, 'fmap');

  if exist(pth, 'dir')

    file_list = return_file_list('fmap', subject);

    j = 1;

    % -Phase difference image and at least one magnitude image
    % ----------------------------------------------------------------------
    labels = return_labels_fieldmap(file_list, 'phase_difference_image');

    if any(~cellfun(@isempty, labels))

      idx = find(~cellfun(@isempty, labels));

      for i = 1:numel(idx)

        subject.fmap(j).type = 'phasediff';
        subject.fmap(j).filename = file_list{idx(i)};
        subject.fmap(j).magnitude = { ...
                                     strrep(file_list{idx(i)}, ...
                                            '_phasediff.nii', ...
                                            '_magnitude1.nii'), ...
                                     strrep(file_list{idx(i)}, ...
                                            '_phasediff.nii', ...
                                            '_magnitude2.nii')}; % optional

        subject = append_common_fmap_fields_to_structure(subject, labels{idx(i)}, j);

        metafile = return_fmap_metadata_file(subject, file_list{idx(i)});
        subject.fmap(j).meta = struct([]);
        % (!) TODO: file can also be stored at higher levels (inheritance principle)
        if ~isempty(metafile)
          subject.fmap(j).meta = bids.util.jsondecode(metafile);
        end

        j = j + 1;

      end
    end

    % -Two phase images and two magnitude images
    % ----------------------------------------------------------------------
    labels = return_labels_fieldmap(file_list, 'two_phase_image');

    if any(~cellfun(@isempty, labels))

      idx = find(~cellfun(@isempty, labels));

      for i = 1:numel(idx)

        subject.fmap(j).type = 'phase12';
        subject.fmap(j).filename = { ...
                                    file_list{idx(i)}, ...
                                    strrep(file_list{idx(i)}, ...
                                           '_phase1.nii', ...
                                           '_phase2.nii')};
        subject.fmap(j).magnitude = { ...
                                     strrep(file_list{idx(i)}, ...
                                            '_phase1.nii', ...
                                            '_magnitude1.nii'), ...
                                     strrep(file_list{idx(i)}, ...
                                            '_phase1.nii', ...
                                            '_magnitude2.nii')};

        subject = append_common_fmap_fields_to_structure(subject, labels{idx(i)}, j);

        metafile = return_fmap_metadata_file(subject, file_list{idx(i)});
        subject.fmap(j).meta = struct([]);
        % (!) TODO: file can also be stored at higher levels (inheritance principle)
        if ~isempty(metafile)
          subject.fmap(j).meta = { ...
                                  bids.util.jsondecode(metafile), ...
                                  bids.util.jsondecode(strrep(metafile, ...
                                                              '_phase1.json', ...
                                                              '_phase2.json'))};
        end

        j = j + 1;

      end

    end

    % -A single, real fieldmap image
    % ----------------------------------------------------------------------
    labels = return_labels_fieldmap(file_list, 'fieldmap_image');

    if any(~cellfun(@isempty, labels))

      idx = find(~cellfun(@isempty, labels));

      for i = 1:numel(idx)

        subject.fmap(j).type = 'fieldmap';
        subject.fmap(j).filename = file_list{idx(i)};
        subject.fmap(j).magnitude = strrep(file_list{idx(i)}, ...
                                           '_fieldmap.nii', ...
                                           '_magnitude.nii');

        subject = append_common_fmap_fields_to_structure(subject, labels{idx(i)}, j);

        metafile = return_fmap_metadata_file(subject, file_list{idx(i)});
        subject.fmap(j).meta = struct([]);
        % (!) TODO: file can also be stored at higher levels (inheritance principle)
        if ~isempty(metafile)
          subject.fmap(j).meta = bids.util.jsondecode(metafile);
        end

        j = j + 1;

      end
    end

    % -Multiple phase encoded directions (topup)
    % ----------------------------------------------------------------------
    labels = return_labels_fieldmap(file_list, 'phase_encoded_direction_image');

    if any(~cellfun(@isempty, labels))

      idx = find(~cellfun(@isempty, labels));

      for i = 1:numel(idx)

        subject.fmap(j).type = 'epi';
        subject.fmap(j).filename = file_list{idx(i)};
        subject.fmap(j).dir = labels{idx(i)}.dir;

        subject = append_common_fmap_fields_to_structure(subject, labels{idx(i)}, j);

        metafile = return_fmap_metadata_file(subject, file_list{idx(i)});
        subject.fmap(j).meta = struct([]);
        % (!) TODO: file can also be stored at higher levels (inheritance principle)
        if ~isempty(metafile)
          subject.fmap(j).meta = bids.util.jsondecode(metafile);
        end

        j = j + 1;

      end
    end
  end

end

function subject = parse_eeg(subject)
  % --------------------------------------------------------------------------
  % -EEG data
  % --------------------------------------------------------------------------
  pth = fullfile(subject.path, 'eeg');

  if exist(pth, 'dir')

    entities = return_entities('eeg');

    file_list = return_file_list('eeg', subject);

    for i = 1:numel(file_list)

      % European data format (.edf)
      % BrainVision Core Data Format (.vhdr, .vmrk, .eeg) by Brain Products GmbH
      % The format used by the MATLAB toolbox EEGLAB (.set and .fdt files)
      % Biosemi data format (.bdf)

      p = bids.internal.parse_filename(file_list{i}, entities);
      switch p.ext
        case {'.edf', '.vhdr', '.set', '.bdf'}
          % each recording is described with a single file,
          % even though the data can consist of multiple
          subject.eeg = [subject.eeg p];
          subject.eeg(end).meta = struct([]); % ?
        case {'.vmrk', '.eeg', '.fdt'}
          % skip the additional files that come with certain data formats
        otherwise
          % skip unknown files
      end

    end

    file_list = return_event_file_list('eeg', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'eeg');

      subject.eeg(end).meta = bids.util.tsvread(fullfile(pth, file_list{i})); % ?

    end

    file_list = return_channel_description_file_list('eeg', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'eeg');

      subject.eeg(end).meta = bids.util.tsvread(fullfile(pth, file_list{i})); % ?

    end

    file_list = return_session_specific_file_list('eeg', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'eeg');

      subject.eeg(end).meta = struct([]); % ?

    end

  end

end

function subject = parse_meg(subject)
  % --------------------------------------------------------------------------
  % -MEG data
  % --------------------------------------------------------------------------
  pth = fullfile(subject.path, 'meg');

  if exist(pth, 'dir')

    entities = return_entities('meg');

    file_list = return_file_list('meg', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'meg');

      subject.meg(end).meta = struct([]); % ?

    end

    file_list = return_event_file_list('meg', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'meg');

      subject.meg(end).meta = bids.util.tsvread(fullfile(pth, file_list{i})); % ?

    end

    file_list = return_channel_description_file_list('meg', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'meg');

      subject.meg(end).meta = bids.util.tsvread(fullfile(pth, file_list{i})); % ?

    end

    file_list = return_session_specific_file_list('meg', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'meg');

      subject.meg(end).meta = struct([]); % ?

    end

  end

end

function subject = parse_beh(subject)
  % --------------------------------------------------------------------------
  % -Behavioral experiments data
  %
  % - Event timing, metadata, physiological and other continuous recordings
  % --------------------------------------------------------------------------
  pth = fullfile(subject.path, 'beh');

  if exist(pth, 'dir')

    entities = return_entities('beh');

    file_list = return_file_list('beh', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'beh');

    end
  end
end

function subject = parse_dwi(subject)
  % --------------------------------------------------------------------------
  % -Diffusion imaging data
  % --------------------------------------------------------------------------
  pth = fullfile(subject.path, 'dwi');

  if exist(pth, 'dir')

    entities = return_entities('dwi');

    file_list = return_file_list('dwi', subject);

    for i = 1:numel(file_list)

      subject = append_to_structure(file_list{i}, entities, subject, 'dwi');

      % -bval file
      % ------------------------------------------------------------------
      % bval file can also be stored at higher levels (inheritance principle)
      bvalfile = bids.internal.get_metadata(file_list{i}, '^.*%s\\.bval$');
      if isfield(bvalfile, 'filename')
        subject.dwi(end).bval = bids.util.tsvread(bvalfile.filename); % ?
      end

      % -bvec file
      % ------------------------------------------------------------------
      % bvec file can also be stored at higher levels (inheritance principle)
      bvecfile = bids.internal.get_metadata(file_list{i}, '^.*%s\\.bvec$');
      if isfield(bvalfile, 'filename')
        subject.dwi(end).bvec = bids.util.tsvread(bvecfile.filename); % ?
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

function subject = parse_ieeg(subject)
  % --------------------------------------------------------------------------
  % -Human intracranial electrophysiology
  % --------------------------------------------------------------------------
  pth = fullfile(subject.path, 'ieeg');

  if exist(pth, 'dir')

    entities = return_entities('ieeg');

    file_list = return_file_list('ieeg', subject);

    for i = 1:numel(file_list)

      % European Data Format (.edf)
      % BrainVision Core Data Format (.vhdr, .eeg, .vmrk) by Brain Products GmbH
      % The format used by the MATLAB toolbox EEGLAB (.set and .fdt files)
      % Neurodata Without Borders (.nwb)
      % MEF3 (.mef)

      p = bids.internal.parse_filename(file_list{i}, entities);
      switch p.ext
        case {'.edf', '.vhdr', '.set', '.nwb', '.mef'}
          % each recording is described with a single file,
          % even though the data can consist of multiple
          subject.ieeg = [subject.ieeg p];
          subject.ieeg(end).meta = struct([]); % ?
        case {'.vmrk', '.eeg', '.fdt'}
          % skip the additional files that come with certain data formats
        otherwise
          % skip unknown files
      end

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

function subject = append_common_fmap_fields_to_structure(subject, labels, idx)

  subject.fmap(idx).ses = regexprep(labels.ses, '^_[a-zA-Z0-9]+-', '');
  subject.fmap(idx).acq = regexprep(labels.acq, '^_[a-zA-Z0-9]+-', '');
  subject.fmap(idx).run = regexprep(labels.run, '^_[a-zA-Z0-9]+-', '');

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

    case 'anat'
      entities = {'sub', 'ses', 'acq', 'ce', 'rec', 'fa', 'echo', 'inv', 'run'};

    case 'func'
      entities = {'sub', ...
                  'ses', ...
                  'task', ...
                  'acq', ...
                  'rec', ...
                  'fa', ...
                  'echo', ...
                  'dir', ...
                  'inv', ...
                  'run', ...
                  'recording', ...
                  'meta'};

    case {'eeg', 'ieeg'}
      entities = {'sub', 'ses', 'task', 'acq', 'run', 'meta'};

    case 'meg'
      entities = {'sub', 'ses', 'task', 'acq', 'run', 'proc', 'meta'};

    case 'beh'
      entities = {'sub', 'ses', 'task'};

    case 'dwi'
      entities = {'sub', 'ses', 'acq', 'run', 'bval', 'bvec'};

    case 'pet'
      entities = {'sub', 'ses', 'task', 'acq', 'rec', 'run'};

  end
end

function labels = return_labels_fieldmap(file_list, fiefmap_type)

  direction_pattern = '';

  switch fiefmap_type

    case 'phase_difference_image'
      suffix = 'phasediff';

    case 'two_phase_image'
      suffix = 'phase1';

    case 'fieldmap_image'
      suffix = 'fieldmap';

    case 'phase_encoded_direction_image'
      suffix = 'epi';

      direction_pattern = '_dir-(?<dir>[a-zA-Z0-9]+)?';

  end

  labels = regexp(file_list, [ ...
                              '^sub-[a-zA-Z0-9]+', ...          % sub-<participant_label>
                              '(?<ses>_ses-[a-zA-Z0-9]+)?', ... % ses-<label>
                              '(?<acq>_acq-[a-zA-Z0-9]+)?', ... % acq-<label>
                              direction_pattern, ...            % dir-<index>
                              '(?<run>_run-[a-zA-Z0-9]+)?', ... % run-<index>
                              '_' suffix '\.nii(\.gz)?$'], 'names');   % NIfTI file extension

end

% TODO
%
% more refactoring can be done across the several 'return_X_file_list' functions
%

function file_list = return_file_list(modality, subject)

  switch modality

    case 'anat'
      pattern = '_([a-zA-Z0-9]+){1}\\.nii(\\.gz)?';

    case 'func'
      pattern = '_task-.*_bold\\.nii(\\.gz)?';

    case 'fmap'
      pattern = '\\.nii(\\.gz)?';

    case 'eeg'
      pattern = '_task-.*_eeg\\..*[^json]';

    case 'meg'
      pattern = '_task-.*_meg\\..*[^json]';

    case 'beh'
      pattern = '_(events\\.tsv|beh\\.json|physio\\.tsv\\.gz|stim\\.tsv\\.gz)';

    case 'dwi'
      pattern = '_([a-zA-Z0-9]+){1}\\.nii(\\.gz)?';

    case 'pet'
      pattern = '_task-.*_pet\\.nii(\\.gz)?';

    case 'ieeg'
      pattern = '_task-.*_ieeg\\..*[^json]';

  end

  pth = fullfile(subject.path, modality);

  [file_list, d] = bids.internal.file_utils('List', ...
                                            pth, ...
                                            sprintf(['^%s.*' pattern '$'], ...
                                                    subject.name));

  if strcmp(modality, 'meg') && isempty(file_list)
    file_list = d;
  end

  file_list = convert_to_cell(file_list);

end

function file_list = return_event_file_list(modality, subject)
  %
  % TODO: events file can also be stored at higher levels (inheritance principle)
  %

  switch modality

    case {'func', 'eeg', 'meg'}
      pattern = '_task-.*_events\\.tsv';

  end

  pth = fullfile(subject.path, modality);

  [file_list, d] = bids.internal.file_utils('List', ...
                                            pth, ...
                                            sprintf(['^%s.*' pattern '$'], ...
                                                    subject.name));

  file_list = convert_to_cell(file_list);

end

function file_list = return_physio_stim_file_list(modality, subject)
  %
  % Physiological and other continuous recordings file
  %
  % TODO: stim files can also be stored at higher levels (inheritance principle)
  %

  switch modality

    case {'func'}
      pattern = '_task-.*_(physio|stim)\\.tsv\\.gz';

  end

  pth = fullfile(subject.path, modality);

  [file_list, d] = bids.internal.file_utils('List', ...
                                            pth, ...
                                            sprintf(['^%s.*' pattern '$'], ...
                                                    subject.name));

  file_list = convert_to_cell(file_list);

end

function metafile = return_fmap_metadata_file(subject, fmap_file)

  pth = fullfile(subject.path, 'fmap');

  fb = bids.internal.file_utils(bids.internal.file_utils( ...
                                                         fmap_file, ...
                                                         'basename'), ...
                                'basename');
  metafile = fullfile(pth, bids.internal.file_utils(fb, 'ext', 'json'));

  if ~exist(metafile, 'file')
    metafile = [];
  end

end

function file_list = return_channel_description_file_list(modality, subject)
  %
  % Channel description table
  %
  % TODO: those files can also be stored at higher levels (inheritance principle)
  %

  switch modality

    case {'eeg', 'meg'}
      pattern = '_task-.*_channels\\.tsv';

  end

  pth = fullfile(subject.path, modality);

  [file_list, d] = bids.internal.file_utils('List', ...
                                            pth, ...
                                            sprintf(['^%s.*' pattern '$'], ...
                                                    subject.name));

  file_list = convert_to_cell(file_list);

end

function file_list = return_session_specific_file_list(modality, subject)

  switch modality

    case {'eeg', 'meg'}
      pattern = [ ...
                 '(_ses-[a-zA-Z0-9]+)?.*_', ...
                 '(electrodes\\.tsv|photo\\.jpg|coordsystem\\.json|headshape\\..*)'];

  end

  pth = fullfile(subject.path, modality);

  [file_list, d] = bids.internal.file_utils('List', ...
                                            pth, ...
                                            sprintf(['^%s' pattern '$'], ...
                                                    subject.name));

  file_list = convert_to_cell(file_list);

end
