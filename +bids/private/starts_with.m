function tf = starts_with(s, pattern, str, boolean)

% STARTS_WITH is a drop-in replacement for startsWith, which was introduced in MATLAB R2016b.
%
% This code is based on the startsWith function that is part of FieldTrip, see 
% https://github.com/fieldtrip/fieldtrip/blob/master/compat/matlablt2016b/startsWith.m
%
% Copyright (C) 2017-2019 Jan Mathijs Schoffelen, Donders Institute for Brain, Cognition and Behaviour

if ~ischar(s) && ~iscellstr(s)
  error('the input should be either a char-array or a cell-array with chars');
end
if nargin<4
  boolean = false;
end
if nargin<3
  str = 'IgnoreCase';
end
if ~strcmpi(str, 'ignorecase')
  error('incorrect third input argument, can only be ''IgnoreCase''');
end
if ~islogical(boolean)
  error('fourth input argument should be a logical scalar');
end

if boolean
  tf = strncmpi(s, pattern, numel(pattern));
else
  tf = strncmp(s, pattern, numel(pattern));
end

