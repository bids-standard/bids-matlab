% # BIDS-Matlab: derivatives
%
% (C) Copyright 2021 BIDS-MATLAB developers

%%

add_bids_matlab_to_path();

% ## Indexing derivatives
%
% Let's work on an `fmriprep` dataset.
%
% To work with derivatives data, we must ignore the BIDS schema for indexing.

%%

use_schema = false();

BIDS = bids.layout(fullfile(pwd, 'bids-examples', 'ds000001-fmriprep'), ...
                   'use_schema', false);

%%

bids.query(BIDS, 'modalities');

% The dataset description `DatasetType` confirms we are working with a derivative dataset.

%%

BIDS.description;

% We can access any preprocessed data by querying
% for data described (`desc` entitiy) as preprocessed (`preproc`)
% and maybe also in which `space` we want to work in.

%%

bids.query(BIDS, 'data', 'modality', 'anat',  'desc', 'preproc', 'space', 'MNI152NLin2009cAsym');

%
% But we can also get the surface data from Freesurfer.

%%

bids.query(BIDS, 'data', 'sub', '10', 'modality', 'func', 'space', 'fsaverage5');

%%

bids.query(BIDS, 'data', 'sub', '10', 'desc', 'confounds');

% We can also directly look up json files when we don't use the BIDS schema.

%%

bids.query(BIDS, 'extensions');

%%

filter.sub = '10';
bids.query(BIDS, 'data', filter);

%%

filter.space = 'MNI152NLin2009cAsym';
filter.desc = 'preproc';
filter.run = '3';
json_file = bids.query(BIDS, 'data', filter);
bids.util.jsondecode(json_file{1});

% ## Indexing nested derivatives

%%

warning('OFF');

%%

BIDS = bids.layout(fullfile(pwd, 'bids-examples', 'ds000117'), ...
                   'use_schema', false, ...
                   'index_derivatives', true);

%%

bids.query(BIDS.derivatives.meg_derivatives, 'subjects');

% ## Copying a raw dataset to start a new analysis
%
% Let's work on an `fmriprep` dataset.
%
% To work with derivatives data, we must ignore the BIDS schema for indexing.

%%

dataset = fullfile(pwd, 'bids-examples', 'qmri_vfa');

output_path = fullfile(pwd, 'output');

filter =  struct('modality', 'anat');

pipeline_name = 'SPM12';

bids.copy_to_derivative(dataset, ...
                        'pipeline_name', pipeline_name, ...
                        'output_path', output_path, ...
                        'filter', filter, ...
                        'force', true, ...
                        'unzip', false, ...
                        'verbose', true);

%%

BIDS = bids.layout(fullfile(output_path, 'SPM12'));
BIDS.description.GeneratedBy;
