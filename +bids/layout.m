function BIDS = layout(root)
% Parse a directory structure formated according to the BIDS standard
% FORMAT BIDS = bids.layout(root)
% root   - directory formated according to BIDS [Default: pwd]
% BIDS   - structure containing the BIDS file layout
%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers


%-Validate input arguments
%==========================================================================
if ~nargin
    root = pwd;
elseif nargin == 1
    if ischar(root)
        root = file_utils(root, 'CPath');
    elseif isstruct(root)
        BIDS = root; % or BIDS = bids.layout(root.root);
        return;
    else
        error('Invalid input: root must be a char filename or a BIDS struct; got a %s',...
            class(root));
    end
end

%-BIDS structure
%==========================================================================

BIDS = struct(...
    'dir',root, ...               % BIDS directory
    'description',struct([]), ... % content of dataset_description.json
    'sessions',{{}},...           % cellstr of sessions
    'scans',struct([]),...        % content of sub-<participant_label>_scans.tsv (should go within subjects)
    'sess',struct([]),...         % content of sub-<participants_label>_sessions.tsv (should go within subjects)
    'participants',struct([]),... % content of participants.tsv
    'subjects',struct([]));       % structure array of subjects

%-Validation of BIDS root directory
%==========================================================================
if ~exist(BIDS.dir,'dir')
    error('BIDS directory does not exist: ''%s''',BIDS.dir);
elseif ~exist(fullfile(BIDS.dir,'dataset_description.json'),'file')
    error('BIDS directory not valid: missing dataset_description.json: ''%s''',...
        BIDS.dir);
end

%-Dataset description
%==========================================================================
try
    BIDS.description = bids.util.jsondecode(fullfile(BIDS.dir,'dataset_description.json'));
catch err
    error('BIDS dataset description could not be read: %s',err.message);
end
if ~isfield(BIDS.description,'BIDSVersion')
    error('BIDS dataset description not valid: missing BIDSVersion field');
end
if ~isfield(BIDS.description,'Name')
    error('BIDS dataset description not valid: missing Name field');
end

% See also optional README and CHANGES files

%-Optional directories
%==========================================================================
% [code/]
% [derivatives/]
% [stimuli/]
% [sourcedata/]
% [phenotype/]

%-Scans key file
%==========================================================================

% sub-<participant_label>/[ses-<session_label>/]
%     sub-<participant_label>_scans.tsv

%-Participant key file
%==========================================================================
p = file_utils('FPList',BIDS.dir,'^participants\.tsv$');
if ~isempty(p)
    BIDS.participants = bids.util.tsvread(p);
end
p = file_utils('FPList',BIDS.dir,'^participants\.json$');
if ~isempty(p)
    BIDS.participants.meta = bids.util.jsondecode(p);
end

%-Sessions file
%==========================================================================

% sub-<participant_label>/[ses-<session_label>/]
%      sub-<participant_label>[_ses-<session_label>]_sessions.tsv

%-Tasks: JSON files are accessed through metadata
%==========================================================================
%t = file_utils('FPList',BIDS.dir,...
%    '^task-.*_(beh|bold|events|channels|physio|stim|meg)\.(json|tsv)$');

%-Subjects
%==========================================================================
sub = cellstr(file_utils('List',BIDS.dir,'dir','^sub-.*$'));
if isequal(sub,{''})
    error('No subjects found in BIDS directory.');
end

for su=1:numel(sub)
    sess = cellstr(file_utils('List',fullfile(BIDS.dir,sub{su}),'dir','^ses-.*$'));    
    for se=1:numel(sess)
        if isempty(BIDS.subjects)
            BIDS.subjects = parse_subject(BIDS.dir, sub{su}, sess{se});
        else
            BIDS.subjects(end+1) = parse_subject(BIDS.dir, sub{su}, sess{se});
        end
    end
end


%==========================================================================
%-Parse a subject's directory
%==========================================================================
function subject = parse_subject(p, subjname, sesname)
% For each modality (anat, func, eeg...) all the files from the
% corresponding directory are listed and their filename parsed with extra
% BIDS valid entities listed (e.g. 'acq','ce','rec','fa'...).

subject.name    = subjname;   % subject name ('sub-<participant_label>')
subject.path    = fullfile(p,subjname,sesname); % full path to subject directory
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


%--------------------------------------------------------------------------
%-Anatomy imaging data
%--------------------------------------------------------------------------
pth = fullfile(subject.path,'anat');
if exist(pth,'dir')
    f = file_utils('List',pth,...
        sprintf('^%s.*_([a-zA-Z0-9]+){1}\\.nii(\\.gz)?$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        %-Anatomy imaging data file
        %------------------------------------------------------------------
        p = parse_filename(f{i}, {'sub','ses','acq','ce','rec','fa','echo','inv','run'});
        subject.anat = [subject.anat p];
        
    end
end

%--------------------------------------------------------------------------
%-Task imaging data
%--------------------------------------------------------------------------
pth = fullfile(subject.path,'func');
if exist(pth,'dir')
    
    %-Task imaging data file
    %----------------------------------------------------------------------
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_bold\\.nii(\\.gz)?$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','rec','fa','echo','inv','run','recording', 'meta'});
        subject.func = [subject.func p];
        subject.func(end).meta = struct([]); % ?
        
    end
    
    %-Task events file
    %----------------------------------------------------------------------
    % (!) TODO: events file can also be stored at higher levels (inheritance principle)
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_events\\.tsv$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','rec','fa','echo','inv','run','recording', 'meta'});
        subject.func = [subject.func p];
        subject.func(end).meta = bids.util.tsvread(fullfile(pth,f{i})); % ?

    end
        
    %-Physiological and other continuous recordings file
    %----------------------------------------------------------------------
    % (!) TODO: stim file can also be stored at higher levels (inheritance principle)
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_(physio|stim)\\.tsv\\.gz$',subject.name));
    % see also [_recording-<label>]
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','rec','fa','echo','inv','run','recording', 'meta'});
        subject.func = [subject.func p];
        subject.func(end).meta = struct([]); % ?
         
    end
end

%--------------------------------------------------------------------------
%-Fieldmap data
%--------------------------------------------------------------------------
pth = fullfile(subject.path,'fmap');
if exist(pth,'dir')
    f = file_utils('List',pth,...
        sprintf('^%s.*\\.nii(\\.gz)?$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    j = 1;

    %-Phase difference image and at least one magnitude image
    %----------------------------------------------------------------------
    labels = regexp(f,[...
        '^sub-[a-zA-Z0-9]+' ...              % sub-<participant_label>
        '(?<ses>_ses-[a-zA-Z0-9]+)?' ...     % ses-<label>
        '(?<acq>_acq-[a-zA-Z0-9]+)?' ...     % acq-<label>
        '(?<run>_run-[a-zA-Z0-9]+)?' ...     % run-<index>
        '_phasediff\.nii(\.gz)?$'],'names'); % NIfTI file extension
    if any(~cellfun(@isempty,labels))
        idx = find(~cellfun(@isempty,labels));
        for i=1:numel(idx)
            fb = file_utils(file_utils(f{idx(i)},'basename'),'basename');
            metafile = fullfile(pth,file_utils(fb,'ext','json'));
            subject.fmap(j).type = 'phasediff';
            subject.fmap(j).filename = f{idx(i)};
            subject.fmap(j).magnitude = {...
                strrep(f{idx(i)},'_phasediff.nii','_magnitude1.nii'),...
                strrep(f{idx(i)},'_phasediff.nii','_magnitude2.nii')}; % optional
            subject.fmap(j).ses = regexprep(labels{idx(i)}.ses,'^_[a-zA-Z0-9]+-','');
            subject.fmap(j).acq = regexprep(labels{idx(i)}.acq,'^_[a-zA-Z0-9]+-','');
            subject.fmap(j).run = regexprep(labels{idx(i)}.run,'^_[a-zA-Z0-9]+-','');
            if exist(metafile,'file')
                subject.fmap(j).meta = bids.util.jsondecode(metafile);
            else
                % (!) TODO: file can also be stored at higher levels (inheritance principle)
                subject.fmap(j).meta = struct([]); % ?
            end
            j = j + 1;
        end
    end

    %-Two phase images and two magnitude images
    %----------------------------------------------------------------------
    labels = regexp(f,[...
        '^sub-[a-zA-Z0-9]+' ...           % sub-<participant_label>
        '(?<ses>_ses-[a-zA-Z0-9]+)?' ...  % ses-<label>
        '(?<acq>_acq-[a-zA-Z0-9]+)?' ...  % acq-<label>
        '(?<run>_run-[a-zA-Z0-9]+)?' ...  % run-<index>
        '_phase1\.nii(\.gz)?$'],'names'); % NIfTI file extension
    if any(~cellfun(@isempty,labels))
        idx = find(~cellfun(@isempty,labels));
        for i=1:numel(idx)
            fb = file_utils(file_utils(f{idx(i)},'basename'),'basename');
            metafile = fullfile(pth,file_utils(fb,'ext','json'));
            subject.fmap(j).type = 'phase12';
            subject.fmap(j).filename = {...
                f{idx(i)},...
                strrep(f{idx(i)},'_phase1.nii','_phase2.nii')};
            subject.fmap(j).magnitude = {...
                strrep(f{idx(i)},'_phase1.nii','_magnitude1.nii'),...
                strrep(f{idx(i)},'_phase1.nii','_magnitude2.nii')};
            subject.fmap(j).ses = regexprep(labels{idx(i)}.ses,'^_[a-zA-Z0-9]+-','');
            subject.fmap(j).acq = regexprep(labels{idx(i)}.acq,'^_[a-zA-Z0-9]+-','');
            subject.fmap(j).run = regexprep(labels{idx(i)}.run,'^_[a-zA-Z0-9]+-','');
            if exist(metafile,'file')
                subject.fmap(j).meta = {...
                    bids.util.jsondecode(metafile),...
                    bids.util.jsondecode(strrep(metafile,'_phase1.json','_phase2.json'))};
            else
                % (!) TODO: file can also be stored at higher levels (inheritance principle)
                subject.fmap(j).meta = struct([]); % ?
            end
            j = j + 1;
        end
    end

    %-A single, real fieldmap image
    %----------------------------------------------------------------------
    labels = regexp(f,[...
        '^sub-[a-zA-Z0-9]+' ...             % sub-<participant_label>
        '(?<ses>_ses-[a-zA-Z0-9]+)?' ...    % ses-<label>
        '(?<acq>_acq-[a-zA-Z0-9]+)?' ...    % acq-<label>
        '(?<run>_run-[a-zA-Z0-9]+)?' ...    % run-<index>
        '_fieldmap\.nii(\.gz)?$'],'names'); % NIfTI file extension
    if any(~cellfun(@isempty,labels))
        idx = find(~cellfun(@isempty,labels));
        for i=1:numel(idx)
            fb = file_utils(file_utils(f{idx(i)},'basename'),'basename');
            metafile = fullfile(pth,file_utils(fb,'ext','json'));
            subject.fmap(j).type = 'fieldmap';
            subject.fmap(j).filename = f{idx(i)};
            subject.fmap(j).magnitude = strrep(f{idx(i)},'_fieldmap.nii','_magnitude.nii');
            subject.fmap(j).ses = regexprep(labels{idx(i)}.ses,'^_[a-zA-Z0-9]+-','');
            subject.fmap(j).acq = regexprep(labels{idx(i)}.acq,'^_[a-zA-Z0-9]+-','');
            subject.fmap(j).run = regexprep(labels{idx(i)}.run,'^_[a-zA-Z0-9]+-','');
            if exist(metafile,'file')
                subject.fmap(j).meta = bids.util.jsondecode(metafile);
            else
                % (!) TODO: file can also be stored at higher levels (inheritance principle)
                subject.fmap(j).meta = struct([]); % ?
            end
            j = j + 1;
        end
    end

    %-Multiple phase encoded directions (topup)
    %----------------------------------------------------------------------
    labels = regexp(f,[...
        '^sub-[a-zA-Z0-9]+' ...          % sub-<participant_label>
        '(?<ses>_ses-[a-zA-Z0-9]+)?' ... % ses-<label>
        '(?<acq>_acq-[a-zA-Z0-9]+)?' ... % acq-<label>
        '_dir-(?<dir>[a-zA-Z0-9]+)?' ... % dir-<index>
        '(?<run>_run-[a-zA-Z0-9]+)?' ... % run-<index>
        '_epi\.nii(\.gz)?$'],'names');   % NIfTI file extension
    if any(~cellfun(@isempty,labels))
        idx = find(~cellfun(@isempty,labels));
        for i=1:numel(idx)
            fb = file_utils(file_utils(f{idx(i)},'basename'),'basename');
            metafile = fullfile(pth,file_utils(fb,'ext','json'));
            subject.fmap(j).type = 'epi';
            subject.fmap(j).filename = f{idx(i)};
            subject.fmap(j).ses = regexprep(labels{idx(i)}.ses,'^_[a-zA-Z0-9]+-','');
            subject.fmap(j).acq = regexprep(labels{idx(i)}.acq,'^_[a-zA-Z0-9]+-','');
            subject.fmap(j).dir = labels{idx(i)}.dir;
            subject.fmap(j).run = regexprep(labels{idx(i)}.run,'^_[a-zA-Z0-9]+-','');
            if exist(metafile,'file')
                subject.fmap(j).meta = bids.util.jsondecode(metafile);
            else
                % (!) TODO: file can also be stored at higher levels (inheritance principle)
                subject.fmap(j).meta = struct([]); % ?
            end
            j = j + 1;
        end
    end
end

%--------------------------------------------------------------------------
%-EEG data
%--------------------------------------------------------------------------
pth = fullfile(subject.path,'eeg');
if exist(pth,'dir')
    
    %-EEG data file
    %----------------------------------------------------------------------
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_eeg\\..*[^json]$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        % European data format (.edf)
        % BrainVision Core Data Format (.vhdr, .vmrk, .eeg) by Brain Products GmbH
        % The format used by the MATLAB toolbox EEGLAB (.set and .fdt files)
        % Biosemi data format (.bdf)

        p = parse_filename(f{i}, {'sub','ses','task','acq','run','meta'});
        switch p.ext
          case {'.edf', '.vhdr', '.set', '.bdf'}
            % each recording is described with a single file, even though the data can consist of multiple
            subject.eeg = [subject.eeg p];
            subject.eeg(end).meta = struct([]); % ?
          case {'.vmrk', '.eeg', '.fdt'}
            % skip the additional files that come with certain data formats
          otherwise
            % skip unknown files
        end
        
    end
    
    %-EEG events file
    %----------------------------------------------------------------------
    % (!) TODO: events file can also be stored at higher levels (inheritance principle)
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_events\\.tsv$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','run','meta'});
        subject.eeg = [subject.eeg p];
        subject.eeg(end).meta = bids.util.tsvread(fullfile(pth,f{i})); % ?
       
    end
    
    %-Channel description table
    %----------------------------------------------------------------------
    % (!) TODO: events file can also be stored at higher levels (inheritance principle)
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_channels\\.tsv$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','run','meta'});
        subject.eeg = [subject.eeg p];
        subject.eeg(end).meta = bids.util.tsvread(fullfile(pth,f{i})); % ?
        
    end
    
    %-Session-specific file
    %----------------------------------------------------------------------
    f = file_utils('List',pth,...
        sprintf('^%s(_ses-[a-zA-Z0-9]+)?.*_(electrodes\\.tsv|photo\\.jpg|coordsystem\\.json|headshape\\..*)$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','run','meta'});
        subject.eeg = [subject.eeg p];
        subject.eeg(end).meta = struct([]); % ?
        
    end
    
end

%--------------------------------------------------------------------------
%-MEG data
%--------------------------------------------------------------------------
pth = fullfile(subject.path,'meg');
if exist(pth,'dir')
    
    %-MEG data file
    %----------------------------------------------------------------------
    [f,d] = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_meg\\..*[^json]$',subject.name));
    if isempty(f), f = d; end
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','run','proc', 'meta'});
        subject.meg = [subject.meg p];
        subject.meg(end).meta = struct([]); % ?
        
    end
    
    %-MEG events file
    %----------------------------------------------------------------------
    % (!) TODO: events file can also be stored at higher levels (inheritance principle)
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_events\\.tsv$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','run','proc', 'meta'});
        subject.meg = [subject.meg p];
        subject.meg(end).meta = bids.util.tsvread(fullfile(pth,f{i})); % ?
        
    end
        
    %-Channels description table
    %----------------------------------------------------------------------
    % (!) TODO: channels file can also be stored at higher levels (inheritance principle)
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_channels\\.tsv$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','run','proc', 'meta'});
        subject.meg = [subject.meg p];
        subject.meg(end).meta = bids.util.tsvread(fullfile(pth,f{i})); % ?
        
    end

    %-Session-specific file
    %----------------------------------------------------------------------
    f = file_utils('List',pth,...
        sprintf('^%s(_ses-[a-zA-Z0-9]+)?.*_(photo\\.jpg|coordsystem\\.json|headshape\\..*)$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','run','proc', 'meta'});
        subject.meg = [subject.meg p];
        subject.meg(end).meta = struct([]); % ?
        
    end

end

%--------------------------------------------------------------------------
%-Behavioral experiments data
%--------------------------------------------------------------------------
pth = fullfile(subject.path,'beh');
if exist(pth,'dir')
    f = file_utils('FPList',pth,...
        sprintf('^%s.*_(events\\.tsv|beh\\.json|physio\\.tsv\\.gz|stim\\.tsv\\.gz)$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        %-Event timing, metadata, physiological and other continuous
        % recordings
        %------------------------------------------------------------------
        p = parse_filename(f{i}, {'sub','ses','task'});
        subject.beh = [subject.beh p];
        
    end
end

%--------------------------------------------------------------------------
%-Diffusion imaging data
%--------------------------------------------------------------------------
pth = fullfile(subject.path,'dwi');
if exist(pth,'dir')
    f = file_utils('FPList',pth,...
        sprintf('^%s.*_([a-zA-Z0-9]+){1}\\.nii(\\.gz)?$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)

        %-Diffusion imaging file
        %------------------------------------------------------------------
        p = parse_filename(f{i}, {'sub','ses','acq','run', 'bval','bvec'});
        subject.dwi = [subject.dwi p];

        %-bval file
        %------------------------------------------------------------------
        % bval file can also be stored at higher levels (inheritance principle)
        bvalfile = get_metadata(f{i},'^.*%s\\.bval$');
        if isfield(bvalfile,'filename')
            subject.dwi(end).bval = bids.util.tsvread(bvalfile.filename); % ?
        end

        %-bvec file
        %------------------------------------------------------------------
        % bvec file can also be stored at higher levels (inheritance principle)
        bvecfile = get_metadata(f{i},'^.*%s\\.bvec$');
        if isfield(bvalfile,'filename')
            subject.dwi(end).bvec = bids.util.tsvread(bvecfile.filename); % ?
        end
        
    end
end


%--------------------------------------------------------------------------
%-Positron Emission Tomography imaging data
%--------------------------------------------------------------------------
pth = fullfile(subject.path,'pet');
if exist(pth,'dir')
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_pet\\.nii(\\.gz)?$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
        
        %-PET imaging file
        %------------------------------------------------------------------
        p = parse_filename(f{i}, {'sub','ses','task','acq','rec','run'});
        subject.pet = [subject.pet p];
        
    end
end


%--------------------------------------------------------------------------
%-Human intracranial electrophysiology
%--------------------------------------------------------------------------
pth = fullfile(subject.path,'ieeg');
if exist(pth,'dir')
    
    %-iEEG data file
    %----------------------------------------------------------------------
    f = file_utils('List',pth,...
        sprintf('^%s.*_task-.*_ieeg\\..*[^json]$',subject.name));
    if isempty(f), f = {}; else f = cellstr(f); end
    for i=1:numel(f)
      
        % European Data Format (.edf)
        % BrainVision Core Data Format (.vhdr, .eeg, .vmrk) by Brain Products GmbH
        % The format used by the MATLAB toolbox EEGLAB (.set and .fdt files)
        % Neurodata Without Borders (.nwb)
        % MEF3 (.mef)
        
        p = parse_filename(f{i}, {'sub','ses','task','acq','run','meta'});
        switch p.ext
          case {'.edf', '.vhdr', '.set', '.nwb', '.mef'}
            % each recording is described with a single file, even though the data can consist of multiple
            subject.ieeg = [subject.ieeg p];
            subject.ieeg(end).meta = struct([]); % ?
          case {'.vmrk', '.eeg', '.fdt'}
            % skip the additional files that come with certain data formats
          otherwise
            % skip unknown files
        end        
        
    end
    
    %....
end
