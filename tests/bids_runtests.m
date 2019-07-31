function results = bids_runtests(pth)
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


if ~nargin, pth = fileparts(mfilename('fullpath')); end

d = dir(pth);
d([d.isdir]) = [];
d(arrayfun(@(x) isempty(regexp(x.name,'^test_.*\.m$','once')),d)) = [];

results = struct('Passed',{},'Failed',{},'Incomplete',{},'Duration',{});
for i=1:numel(d)
    results(i).Failed = false;
    results(i).Passed = false;
    results(i).Incomplete = false;
    tstart = tic;
    try
        fprintf('%s',d(i).name(1:end-2));
        feval(d(i).name(1:end-2));
        results(i).Passed = true;
    catch
        results(i).Failed = true;
        err = lasterror;
        fprintf('\n%s',err.message);
        rethrow(err)
    end
    results(i).Duration = toc(tstart);
    fprintf('\n');
end

if ~nargout
    fprintf(['Totals (%d tests):\n\t%d Passed, %d Failed, %d Incomplete.\n' ...
        '\t%f seconds testing time.\n\n'],numel(results),nnz([results.Passed]),...
        nnz([results.Failed]),nnz([results.Incomplete]),sum([results.Duration]));
end
