function mustBeA(x, type, label)
%MUSTBEA Require that input is of a given type
%
% bids.internal.mustBeA(x, type, label)
%
% Raises an error if the input x is not of the specified type (or a subclass),
% as determined by isa(x, type).
%
% label is an optional input that determines how the input will be described
% in error messages. If not supplied, `inputname(1)` is used, and if that is
% empty, it falls back to 'input'. 

if nargin < 3; label = []; end

if ~isa(x, type)
  if isempty(label)
    label = inputlabel(1);
  end
  if isempty(label)
    label = 'input';
  end
  error('bids:validators:mustBeA', ...
    '%s must be of type %s; got a %s', ...
    label, type, class (x));
end
end
