function test_tsvread(pth)
% Test the tsvread function
%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________
%
% Copyright (C) 2019, Remi Gau
% Copyright (C) 2019--, BIDS-MATLAB developers
%
%
% Small test to ensure that the functionality of the tsvread function

if ~nargin
    pth = fullfile(fileparts(mfilename('fullpath')),'data','MoAEpilot');
end

% define the expected output from bids query metadata
events.onset = [42 126 210 294 378 462 546];


%% test tsvread on tsv file
tsv_file = fullfile(pth, 'sub-01', 'func', 'sub-01_task-auditory_events.tsv');
output = bids.util.tsvread(tsv_file);
assert(isequal(output.onset', events.onset));


%% test tsvread on zipped tsv file
output = bids.util.tsvread(fullfile(fileparts(mfilename('fullpath')), 'data', 'sub-01_task-auditory_events.tsv.gz'));
assert(isequal(output.onset', events.onset));


