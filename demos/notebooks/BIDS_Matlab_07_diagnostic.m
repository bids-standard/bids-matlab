% # BIDS-matlab: diagnostic
%
% (C) Copyright 2021 BIDS-MATLAB developers

%%

add_bids_matlab_to_path();

%%

BIDS = bids.layout(fullfile(pwd, 'bids-examples', 'ds000247'));

%%

diagnostic_table = bids.diagnostic(BIDS);

%%

diagnostic_table = bids.diagnostic(BIDS, 'split_by', {'task'});
