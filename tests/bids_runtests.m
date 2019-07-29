function bids_runtests(pth)
% Run BIDS tests
%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2019, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2019--, BIDS-MATLAB developers


if ~nargin, pth = pwd; end

d = dir(pth);
d(arrayfun(@(x) x.isdir || ~strncmp(x.name,'test_',5),d)) = [];

sts = true(1,numel(d));
for i=1:numel(d)
    try
        feval(d(i).name);
    catch
        sts(i) = false;
    end
end
if ~all(sts)
    error('One or more tests failed.');
end
