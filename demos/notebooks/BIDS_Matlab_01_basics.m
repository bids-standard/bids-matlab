% # BIDS-Matlab: basics
%
% (C) Copyright 2021 BIDS-MATLAB developers

%%

add_bids_matlab_to_path();

% We will work with the "empty" dataset
% from the bids-examples repository :
% https://github.com/bids-standard/bids-examples

% We use a bit of command line magic to view the top (`head`) directories (`-d`) at a certain level depth (`-L 2`).

% Let's work on the `ds101` dataset.

%%

!tree bids-examples/ds101 -d -L 2 | head

% ## Indexing a dataset
%
% This is done with the `bids.layout` function.

%%

help bids.layout;

%%

BIDS = bids.layout(fullfile(pwd, 'bids-examples', 'ds101'));

% ## Querying a dataset
%
% Make general queries about the dataset are with `bids.query` made on the layout returned by `bids.layout`.

%%

help bids.query;

%%

entities = bids.query(BIDS, 'entities');
disp(entities);

%%

subjects = bids.query(BIDS, 'subjects');
disp(subjects);

%%

sessions = bids.query(BIDS, 'sessions');
disp(sessions);

%%

runs = bids.query(BIDS, 'runs');
disp(runs);

%%

tasks = bids.query(BIDS, 'tasks');
disp(tasks);

%%

suffixes = bids.query(BIDS, 'suffixes');
disp(suffixes);

%%

modalities = bids.query(BIDS, 'modalities');
disp(modalities);

%%

% Make more specific queries
runs = bids.query(BIDS, 'runs', 'suffix', 'T1w');
disp(runs);

%%

runs = bids.query(BIDS, 'runs', 'suffix', 'bold');
disp(runs);

% ### Get filenames

% Get the NIfTI file for subject `'05'`, run `'02'` and task `'Simontask'`:

%%

data = bids.query(BIDS, 'data', 'sub', '05', 'run', '02', 'task', 'Simontask', 'suffix', 'bold');
disp(data);

%  Note that for the entities listed below can be queried using integers:
%  - `'run'`
%  - `'flip'`
%  - `'inv'`
%  - `'split'`
%  - `'echo'`

% This can be also done by creating a structure that can be used as a library.

%%

filter = struct( ...
                'sub', '05', ...
                'run', 1:3, ...
                'task', 'Simontask', ...
                'suffix', 'bold');

%%

data = bids.query(BIDS, 'data', filter);
disp(data);

% You can also query data from several labels or indices

%%

filter.sub = {'01', '03'};

%%

data = bids.query(BIDS, 'data', filter);
disp(data);

% ### Get metadata

% We can also get the metadata of that file including TR:

%%

metadata = bids.query(BIDS, 'metadata', filter);
disp(metadata);

% Get the T1-weighted images from all subjects:

%%

data = bids.query(BIDS, 'data', 'suffix', 'T1w');
disp(data);

% ### Get "dependencies" of a given file

% This can be useful to find the files that are associated with the file you just queried.
%
% In this case the events file for a BOLD run.

%%

filter = struct('sub', '05', ...
                'run', '02', ...
                'task', 'Simontask', ...
                'suffix', 'bold');

dependencies = bids.query(BIDS, 'dependencies', filter);
disp(dependencies);

% ### Using regular expressions

% When using `bids.query` it is possible to use regular expressions.

%%

filter = struct('sub', '0[1-5]', ...
                'run', '02', ...
                'task', 'Simon*', ...
                'suffix', 'bold');

filter = struct('sub', '0[1-3]', ...
                'run', '02', ...
                'task', 'Sim.*', ...
                'suffix', 'bold');

data = bids.query(BIDS, 'data', filter);
disp(data);
