% (C) Copyright 2021 Remi Gau

% TODO turn into a notebook

% demos to show how to use bids-matlab
% to create and edit file BIDS filenames
%
% bids.File is a class that helps you work with BIDS files
%
% - generate valid BIDS or BIDS-like filenames
% - parse existing filenames
% - edit those filenames
% - rename files
% - access that file metadata
%

%% Parsing filenames
bf = bids.File('sub-01_ses-02_task-face_run-01_bold.nii.gz');

disp(bf.suffix);
disp(bf.entities);
disp(bf.extension);

%% Changing parts of the filename

bf = bids.File('sub-01_ses-02_task-face_run-01_bold.nii.gz');
bf.entities.sub = '02';

disp(bf.filename);

%% Removing part of the name

bf = bids.File('sub-01_ses-02_task-face_run-01_bold.nii.gz');
bf.entities.ses = '';

disp(bf.filename);

%% Adding things to the name

bf = bids.File('sub-01_task-face_run-01_bold.nii.gz');
bf.entities.ses = '02';

% oops "ses-02" should be at the beginning
disp(bf.filename);

% let's reorder things
bf = bf.reorder_entities();

% fixed
disp(bf.filename);

% note this also works with the derivatives entities of BIDS
bf.entities.desc = 'mean';
bf.entities.space = 'individual';
bf.entities.hemi = 'L';

bf = bf.reorder_entities();

disp(bf.filename);

%% Generating a filename from scratch

% define the specification of the name to create
spec = struct('ext', '.eeg', ...
              'suffix', 'eeg', ...
              'entities', struct('task', 'lineCrossing', ...
                                 'run', '02', ...
                                 'sub', '01'));

% by default the entities are ordered
% in the way you'entered them
bf = bids.File(spec);
disp(bf.filename);

% but you can use the BIDS schema
% to make sure things are ordered the right way
bf = bids.File(spec, 'use_schema', true);
disp(bf.filename);

%% Checking for valid BIDS filename

% if we forget the required entity "task" for this eeg file
spec = struct('ext', '.eeg', ...
              'suffix', 'eeg', ...
              'entities', struct('run', '02', ...
                                 'sub', '01'));

% using the verbose flag will throw a warning
bids.File(spec, 'use_schema', true, 'verbose', true);

% using the tolerant flag will throw an error
bids.File(spec, 'use_schema', true, 'tolerant', false);

%% Renaming existing files

% let's create a dummy file to work with
% by calling the linux "touch" command
system('touch sub-01_ses-02_task-face_run-01_bold.nii.gz');

input_file = fullfile(pwd, 'sub-01_ses-02_task-face_run-01_bold.nii.gz');

% let's change the filename
bf = bids.File(input_file);
bf.entities.sub = '02';
bf.entities.ses = '';
bf.entities.run = '';

% use the rename method to see how the file WOULD be renamed
bf.rename('verbose', true);

% use "dry_run" false to actually rename the file
bf.rename('verbose', true, ...
          'dry_run', false);

% you may need to use the 'force' parameter
% if you want to overwrite existing files
%
% bf.rename('verbose', true, ...
%           'dry_run', false, ...
%           'force', true);

% let's add a test to make sure the expected file exist
expected_file = fullfile(pwd, 'sub-02_task-face_bold.nii.gz');
assert(exist(expected_file, 'file') == 2);

% we clean up the mess we did
delete(expected_file);

%% Renaming existing files with specification

% same as above but allows you to specify all the changes to apply
% in a single "spec" structure

system('touch sub-01_ses-02_task-face_run-01_bold.nii.gz');
input_file = fullfile(pwd, 'sub-01_ses-02_task-face_run-01_bold.nii.gz');

bf = bids.File(input_file);

spec = struct('entities', struct('desc', 'mean', ...
                                 'ses', '', ...
                                 'run', ''));

bf.rename('spec', spec, ...
          'verbose', true, ...
          'dry_run', false);

expected_file = fullfile(pwd, 'sub-01_task-face_desc-mean_bold.nii.gz');
assert(exist(expected_file, 'file') == 2);

delete('*.nii.gz');

%% Accessing metadata

% creating dummy data
system('touch sub-01_ses-02_task-face_run-01_bold.nii.gz');
% creating dummy metadata
bids.util.jsonencode('sub-01_ses-02_task-face_run-01_bold.json', ...
                     struct('TaskName', 'face', ...
                            'RepetitionTime', 1.5));
% access metadata
input_file = fullfile(pwd, 'sub-01_ses-02_task-face_run-01_bold.nii.gz');

bf = bids.File(input_file);

disp(bf.metadata.TaskName);

disp(bf.metadata.RepetitionTime);

delete('*.nii.gz');
delete('*.json');
