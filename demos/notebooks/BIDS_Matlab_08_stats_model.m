% (C) Copyright 2021 BIDS-MATLAB developers

%%

add_bids_matlab_to_path();

%%

% Create an empty model
bm = bids.Model('init', true);
filename = fullfile(pwd, 'model-empty_smdl.json');
bm.write(filename);

%%

!cat model-empty_smdl.json

%%

% create a default bids model for a dataset
ds = fullfile(pwd, 'bids-examples', 'ds003');
BIDS = bids.layout(ds);

bm = bids.Model();
bm = bm.default(BIDS);

filename = fullfile(pwd, 'model-rhymejudgement_smdl.json');
bm.write(filename);

%%

!cat model-rhymejudgement_smdl.json

%%

% load and query a specific model file
model_file = fullfile('..', '..', 'tests', 'data', 'model', 'model-narps_smdl.json');
bm = bids.Model('file', model_file);

%%

bm.get_nodes('Level', 'Run');

%%

bm.get_transformations('Level', 'Run');
bm.get_dummy_contrasts('Level', 'Run');
bm.get_contrasts('Level', 'Run');
bm.get_model('Level', 'Run');
bm.get_design_matrix('Level', 'Run');
