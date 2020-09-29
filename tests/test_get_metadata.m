function test_get_metadata(pth)
% Test metadata and the inheritance principle
%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2019, Remi Gau
% Copyright (C) 2019--, BIDS-MATLAB developers


% Small test to ensure that metadata are reported correctly
% also tests inheritance principle: metadata are passed on to lower levels 
% unless they are overriden by metadate already present at lower levels

if ~nargin
    pth = fullfile(fileparts(mfilename('fullpath')),'data','MoAEpilot');
end

% define the expected output from bids query metadata
func.RepetitionTime = 7;

func_sub_01.RepetitionTime = 10;

anat.FlipAngle = 5;

anat_sub_01.FlipAngle = 10;
anat_sub_01.Manufacturer = 'Siemens';

% try to get metadata
BIDS = bids.layout(pth);


%% test func metadata base directory
metadata = bids.query(BIDS, 'metadata', 'type', 'bold');
%assert(metadata.RepetitionTime == func.RepetitionTime);


%% test func metadata subject 01
metadata = bids.query(BIDS, 'metadata', 'sub', '01', 'type', 'bold');
%assert(metadata.RepetitionTime == func_sub_01.RepetitionTime);


%% test anat metadata base directory
metadata = bids.query(BIDS, 'metadata', 'type', 'T1w');
%assert(metadata.FlipAngle == anat.FlipAngle);


%% test anat metadata subject 01
metadata = bids.query(BIDS, 'metadata', 'sub', '01', 'type', 'T1w');
assert(metadata.FlipAngle == anat_sub_01.FlipAngle);
assert(strcmp(metadata.Manufacturer, anat_sub_01.Manufacturer));
