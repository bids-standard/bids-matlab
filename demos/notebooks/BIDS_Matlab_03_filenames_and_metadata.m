% # Create filenames, filepaths, and JSON
%
% (C) Copyright 2021 BIDS-MATLAB developers

%%

add_bids_matlab_to_path();

% ## Generating filenames
%
% The vast majority of BIDS filenames have the following pattern:
%
% - a series of `entity-label` pairs separated by `_`
% - a final `_suffix`
% - a file `.extension`
% - pseudo "regular expression" : `entity-label(_entity-label)+_suffix.extension`
%
% `entity`, `label`, `suffix`, `extension` are alphanumeric only (no special character): `()+`
%
%   - For example, suffixes can be `T1w` or `bold` but not `T1w_skullstripped` (no underscore allowed).
%
% Entity and label are separated by a dash: `entity-label --> ()+-()+`
%
%   - For example, you can have: `sub-01` but not `sub-01-blind`
%
% Entity-label pairs are separated by an underscore:
%
%   `entity-label(_entity-label)+ --> ()+-()+(_()+-()+)+`
%
% **Prefixes are not a thing in official BIDS names**
%
%
% BIDS has a number of
% (https://bids-specification.readthedocs.io/en/stable/99-appendices/04-entity-table.html)
% (`sub`, `ses`, `task`...) that must come in a specific order for each suffix.
%
% BIDS derivatives adds a few more entities (`desc`, `space`, `res`...)
% and suffixes (`pseg`, `dseg`, `mask`...)
% that can be used to name and describe preprocessed data.

% The `bids.File` class can help generate BIDS valid file names.

%%

input = struct('ext', '.nii');
input.suffix = 'bold';
input.entities = struct('sub', '01', ...
                        'task', 'faceRecognition', ...
                        'run', '02', ...
                        'ses', 'test');

%%

file = bids.File(input);

file.filename;

% You can rely on the BIDS schema to know in which order the entities must go for a certain `suffix` type.

%%

file = bids.File(input, 'use_schema', true);

file.filename;

% This can also tell you if you are missing a required entity if you set `tolerant` to `false`.

%%

input = struct('ext', '.nii');
input.suffix = 'bold';
input.entities = struct('sub', '01', ...
                        'ses', 'test', ...
                        'run', '02');

% uncomment the line below to see the error
% file = bids.File(input, 'use_schema', true, 'tolerant', false);

% Or you can specify the order of the entities manually.

%%

input = struct('ext', '.nii');
input.suffix = 'bold';
input.entities = struct('sub', '01', ...
                        'task', 'face recognition', ...
                        'run', '02', ...
                        'ses', 'test');
file = bids.File(input);

entity_order = {'run', 'sub', 'ses'};

file = file.reorder_entities(entity_order);
file.filename;

% ## Modifying filenames

% This can be used:
% - to add, remove, modify any of the entities
% - change the suffix
% - change the extensions
% - add or remove any prefix

%%

input = 'sub-01_ses-mri_T1w.nii';
file = bids.File(input, 'use_schema', false);

file.suffix = 'mask';
file.entities.ses = '';
file.entities.desc = 'brain';

file.filename;

% ## Generating file names for derivatives

% This can also be useful to remove the prefix of some files.

%%

input = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';

file = bids.File(input, 'use_schema', false);
file.prefix = '';
file.entities.space = 'IXI549Space';
file.entities.desc = 'preproc';

file.filename;

% This can prove useful to get a dummy json that should accompany any derivatives files.

%%

json = bids.derivatives_json(file.filename);

json.filename;
json.content;

% The content of the JSON should adapt depending on the entities or suffix present in the output filename.

%%

json = bids.derivatives_json('sub-01_ses-test_task-faceRecognition_res-r2pt0_space-IXI549Space_desc-brain_mask.nii');
json.filename;
json.content;
json.content.Resolution;
