% # BIDS-Matlab: TSV and JSON files
%
% (C) Copyright 2021 BIDS-MATLAB developers
%
% ## Read from TSV files
%
% This can be done with the `bids.util.tsvread` function.

%%

add_bids_matlab_to_path();

%%

BIDS = bids.layout(fullfile(pwd, 'bids-examples', 'ieeg_visual'));

%%

bids.query(BIDS, 'subjects');
bids.query(BIDS, 'tasks');
events_file = bids.query(BIDS, 'data', 'sub', '01', 'task', 'visual', 'suffix', 'events');

%%

bids.util.tsvread(events_file{1});

% ## Write to TSV files

%%

tsv_file = fullfile(pwd, 'output', 'sub-01_task-STRUCTURE_events.tsv');

logFile.onset = [2; NaN];
logFile.trial_type = {'motion_up'; 'static'};
logFile.duration = [1; 4];
logFile.speed = [NaN; 4];
logFile.is_fixation = {'true'; '3'};

bids.util.tsvwrite(tsv_file, logFile);

%%

!cat output/sub-01_task-STRUCTURE_events.tsv

% ## Write to JSON files

%%

content = struct('Name', 'test', ...
                 'BIDSVersion', '1.6', ...
                 'DatasetType', 'raw', ...
                 'License', '', ...
                 'Acknowledgements', '', ...
                 'HowToAcknowledge', '', ...
                 'DatasetDOI', '', ...
                 'HEDVersion', '', ...
                 'Funding', {{}}, ...
                 'Authors', {{}}, ...
                 'ReferencesAndLinks', {{}});

bids.util.jsonencode(fullfile(pwd, 'output', 'dataset_description.json'), content);

%%

!cat output/dataset_description.json

% ## Read from JSON files

%%

bids.util.jsondecode(fullfile(pwd, 'output', 'dataset_description.json'));
