function out = layout(root)
% Parse a directory structure formatted according to the BIDS standard
% FORMAT BIDS = bids.layout(root)
% root   - directory formatted according to BIDS [Default: pwd]
% BIDS   - structure containing the BIDS file layout
%
% See also:
% bids

%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers


%-Validate input arguments
%==========================================================================
if nargin < 1
    root = pwd;
else
    if ischar(root)
        root = bids.internal.file_utils(root, 'CPath');
    elseif isa(root, 'bids.BIDSLayout')
        out = root;
        return;
    else
        error('Invalid input: root must be a char filename or a bids.BIDSLayout object; got a %s',...
            class(root));
    end
end

out = bids.BIDSLayout.fromPath(root);