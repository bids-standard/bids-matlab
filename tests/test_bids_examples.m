function test_bids_examples(pth)
% Test datasets from https://github.com/bids-standard/bids-examples
%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2019, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2019--, BIDS-MATLAB developers


if ~nargin, pth = fullfile(pwd,'bids-examples'); end

d = dir(pth);
d(arrayfun(@(x) ~x.isdir || ismember(x.name,{'.','..','.git'}),d)) = [];

sts = true;
for i=1:numel(d)
    try
        BIDS = bids.layout(fullfile(pth,d(i).name));
        evalc('bids.report(BIDS)');
        fprintf('.');
    catch
        sts = false;
        fprintf('X');
        rethrow(lasterror);
    end
end

if ~sts, error('Parsing of BIDS-compatible datasets failed.'); end
