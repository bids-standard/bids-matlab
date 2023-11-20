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

modalities = bids.query(BIDS, 'modalities');
disp(modalities);

% The dataset description `DatasetType` confirms we are working with a derivative dataset.

%%

disp(BIDS.description);

% We can access any preprocessed data by querying
% for data described (`desc` entity) as preprocessed (`preproc`)
% and maybe also in which `space` we want to work in.

%%

data = bids.query(BIDS, 'data', 'modality', 'anat',  'desc', 'preproc', 'space', 'MNI152NLin2009cAsym');
disp(data);

%
% But we can also get the surface data from Freesurfer.

%%

data = bids.query(BIDS, 'data', 'sub', '10', 'modality', 'func', 'space', 'fsaverage5');
disp(data);

%%

data = bids.query(BIDS, 'data', 'sub', '10', 'desc', 'confounds');
disp(data);

% We can also directly look up json files when we don't use the BIDS schema.

%%

extensions = bids.query(BIDS, 'extensions');
disp(extensions);

%%

filter.sub = '10';
data = bids.query(BIDS, 'data', filter);
disp(data);

%%

filter.space = 'MNI152NLin2009cAsym';
filter.desc = 'preproc';
filter.run = '3';
metadata = bids.query(BIDS, 'metadata', filter);
disp(metadata);

% ## Indexing nested derivatives

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
                        'out_path', output_path, ...
                        'filter', filter, ...
                        'force', true, ...
                        'unzip', false, ...
                        'verbose', true);

%%

BIDS = bids.layout(fullfile(output_path, 'SPM12'));
BIDS.description.GeneratedBy;
