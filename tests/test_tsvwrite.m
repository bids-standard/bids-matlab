function test_tsvwrite(pth)
% Test the tsvread function
%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________
%
% Copyright (C) 2020, Remi Gau
% Copyright (C) 2020--, BIDS-MATLAB developers
%
%
% Small test to ensure that the functionality of the tsvwrite function

if ~nargin
    pth = fileparts(mfilename('fullpath'));
end

%% test tsvread on tsv file using structure input

% ---- set up

tsv_file = fullfile(pth, 'sub-01_task-TASK_events.tsv');

logFile(1,1).onset = 2;
logFile(1,1).trial_type = 'motion_up';
logFile(1,1).duration = 1;
logFile(1,1).speed = 2;
logFile(1,1).is_fixation = true;

logFile(2,1).onset = 3;
logFile(2,1).trial_type = 'static';
logFile(2,1).duration = 4;
logFile(2,1).is_fixation = 3;

bids.util.tsvwrite(tsv_file, logFile);


% ---- test section

% read the file
% check the extra columns of the header and some of the content

FID = fopen(fileName, 'r');
C = textscan(FID,'%s%s%s%s%s','Delimiter', '\t', 'EndOfLine', '\n');

assert(isequal(C{4}{1}, 'speed')); % check header

assert(isequal(C{4}{2}, 'NaN')); % check that empty values are entered as NaN
assert(isequal(C{4}{4}, 'NaN')); % check that missing fields are entered as NaN

assert(isequal(str2double(C{5}{4}), 3)); % check values entered properly



%% test tsvread on tsv file using cell input
% TO DO?


%% test tsvread on tsv file using array input
% TO DO?


end


