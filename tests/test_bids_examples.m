function test_bids_examples(pth)
% Test datasets from https://github.com/bids-standard/bids-examples
% This repo is downloaded by the Travis continuous integration and allows
% these tests to be run.
%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2019, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2019--, BIDS-MATLAB developers

% list all the directories in the bids-example folder that are actual
% datasets
if ~nargin, pth = fullfile(pwd,'bids-examples'); end

d = dir(pth);
d(arrayfun(@(x) ~x.isdir || ismember(x.name,{'.','..','.git'}),d)) = [];

% try to run bids.layout on each dataset folder and keep track of any
% failure with a try/catch
sts = false(1,numel(d));
msg = cell(1,numel(d));
for i=1:numel(d)
    try
        BIDS = bids.layout(fullfile(pth,d(i).name));
        sts(i) = true;
        fprintf('.');
    catch
        fprintf('X');
        le = lasterror;
        msg{i} = le.message;
    end
end
fprintf('\n');

% lists all the folder for which bids.layout failed
if ~all(sts)
    for i=find(~sts)
        fprintf('* %s: %s\n',d(i).name,msg{i});
    end
    error('Parsing of BIDS-compatible datasets failed.');
end
