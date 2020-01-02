function result = query(layout,query,varargin)
% QUERY Query a directory structure formatted according to the BIDS standard
%
% result = bids.query(layout,query,...)
%
% layout - BIDS directory name or BIDSLayout object (from bids.layout)
%
% query  - type of query: {'data', 'metadata', 'sessions', 'subjects',
%          'runs', 'tasks', 'runs', 'types', 'modalities'}
%
% ...    - name/value pairs for query filter specification
%
% Returns:
%
% result - outcome of query
%
% See also:
% bids
% bids.layout.BIDSLayout.query

%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers

narginchk(2,Inf);

layout = bids.readlayout(layout);

result = layout.query(query,varargin{:});
