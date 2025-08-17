% # BIDS-matlab: reports
%
% (C) Copyright 2021 BIDS-MATLAB developers

%%

add_bids_matlab_to_path();

%%

BIDS = bids.layout(fullfile(pwd, 'bids-examples', 'ds101'));

%%

read_nifti = false;
output_path = fullfile(pwd, 'output');
verbose = true;

bids.report(BIDS, ...
            'output_path', output_path, ...
            'read_nifti', read_nifti, ...
            'verbose', verbose);
