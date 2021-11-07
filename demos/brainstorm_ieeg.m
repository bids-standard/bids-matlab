% (C) Copyright 2021 Remi Gau

force = true;
verbose =  true;
use_schema =  true;
tolerant = false;
pipeline_name = 'bids_matlab';

%%
pth = bids.util.download_ds('source', 'brainstorm', ...
                            'demo', 'ieeg', ...
                            'force', force, ...
                            'verbose', verbose);

%%
BIDS = bids.layout(pth, ...
                   use_schema, ...
                   tolerant, ...
                   verbose);

bids.copy_to_derivative(BIDS, pipeline_name, ...
                        fullfile(pth, 'derivatives'), ...
                        'unzip', true, ...
                        'force', force, ...
                        'skip_dep', false, ...
                        'use_schema', use_schema, ...
                        'verbose', verbose);

%%
BIDS = bids.layout(fullfile(pth, 'derivatives', pipeline_name), ...
                   use_schema, ...
                   tolerant, ...
                   verbose);

mkdir(fullfile(pth, 'derivatives', pipeline_name, 'log'));
bids.report(BIDS, ...
            'output_path', fullfile(pth, 'derivatives', pipeline_name, 'log'), ...
            'read_nifti', true, ...
            'verbose', verbose);

%%

bids.query(BIDS, 'data', 'suffix', 'T1w');
bids.query(BIDS, 'data', 'suffix', 'meg');
