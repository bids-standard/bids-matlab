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
  end

  % -Dataset description
  % ==========================================================================

  % Note: Can be moved to validator, but still can be usefull to
  % detect if dataset is from derivatives

  if ~exist(fullfile(BIDS.dir, 'dataset_description.json'), 'file')
    msg = sprintf('BIDS directory not valid: missing dataset_description.json: ''%s''', ...
                  BIDS.dir);
    tolerant_message(tolerant, msg);
  else
    try
      BIDS.description = bids.util.jsondecode(fullfile(BIDS.dir, 'dataset_description.json'));

      fields_to_check = {'BIDSVersion', 'Name'};
      for iField = 1:numel(fields_to_check)
        if ~isfield(BIDS.description, fields_to_check{iField})
          msg = sprintf('BIDS dataset description not valid: missing %s field.', ...
                        fields_to_check{iField});
          tolerant_message(tolerant, msg);
        end
      end
    catch err
      msg = sprintf('BIDS dataset description could not be read: %s', err.message);
      error(msg);
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


  % subject.name      -- subject name ('sub-<participant_label>')
  % subject.path      -- full path to subject directory
  % subject.session   -- session name ('' or 'ses-<label>')
  % subject.modality  -- substructure containing found modalities

  subject = struct('name', subjname, ...
                   'path', fullfile(pth, subjname, sesname), ...
                   'session', sesname, ...
                   'modality', [] ...
                   );
  modalities = cellstr(bids.internal.file_utils('List', subject.path, 'dir', '^[a-zA-Z0-9]+$'));
  disp(modalities);

  for iMod = 1:numel(modalities)
    subject = parse_modality(subject, modalities{iMod});
  end

end

function subject = parse_modality(subject, modality)

  pth = fullfile(subject.path, modality);

  if exist(pth, 'dir')

    file_list = return_file_list(modality, subject);

    if isempty(file_list)
      warning([subject.path, ': Modality ', modality, ...
               'do not contain data']);
    end

    subject.modality.(modality) = struct([]);
    for i = 1:numel(file_list)
      p = bids.internal.parse_filename(file_list{i});

      % checking for json file
      basename = regexprep(file_list{i}, [p.ext '$'], '');
      metaname = fullfile(pth, [basename '.json']);
      if exist(metaname, 'file')
        p.metafile = metaname;
      else
        warning([file_list{i} ' missing sidecar json file']);
        p.metafile = '';
      end

      p.intended = {};
      if p.tab % tabular file
        % scanning all files that are not tabular
        for ii=1:numel(file_list{i})
          if startsWith(filelist{ii}, p.basename) && ~ endsWith(file_list{ii}, '.tsv')
            p.intended{end+1} = fullfile(subject.session, modalities{mod}, filelist{ii});
          end
        end
      elseif ~isempty(p.metafile) % image file with meta data
        js = bids.util.jsondecode(p.metafile);
        if isfield(js, 'IntendedFor')
          % ugly, but bids require paths from subject folder
          sub_path = subject.path(1:end - length(subject.session));
          p.intended = transform_intended(js.IntendedFor, sub_path);
        end
      end
      subject.modality.(modality) = [subject.modality.(modality) p];
    end
  end

end

% --------------------------------------------------------------------------
%                            HELPER FUNCTIONS
% --------------------------------------------------------------------------

function f = convert_to_cell(f)
  if isempty(f)
    f = {};
  else
    f = cellstr(f);
  end
end


function file_list = return_file_list(modality, subject)
  if isempty(subject.session)
    prefix = sprintf('%s_', subject.name);
  else
    prefix = sprintf('%s_%s_', subject.name, subject.session);
  end

  % common pattern for all modalities
  pattern = sprintf(['^%s'... % subject & session
                     '([a-zA-Z0-9]+-[a-zA-Z0-9]+_)*'... % entities
                     '([a-zA-Z0-9]+){1}'... % suffix
                     '\\.(?!json)[a-zA-Z0-9.]+$'... % extention
                     ], prefix);

  pth = fullfile(subject.path, modality);

  [file_list, d] = bids.internal.file_utils('List', ...
                                            pth, ...
                                            pattern);
  file_list = convert_to_cell(file_list);
end


function flist = transform_intended(intended, sub_path)
  % loops over list of intended for files, checks their existance and transforms
  % to absolute path
  flist = {};
  if ~iscell(intended)
      intended = {intended};
  end

  for i = 1:numel(intended)
      fi = fullfile(sub_path, intended{i});
      if ~exist(fi, 'file')
          warning(['IntendedFor: ', intended{i}, ' not found in ', sub_path]);
      else
        flist{end+1} = fi;
      end
  end
end
