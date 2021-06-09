function varargout = jsonencode(varargin)
  %
  % Encode data to JSON-formatted file
  %
  % USAGE::
  %
  %   bids.util.jsonencode(filename, json, opts)
  %
  % :param filename: JSON filename
  % :type filename: string
  % :param json: JSON structure
  % :type json: structure
  %
  %
  % USAGE::
  %
  %   S = bids.util.jsonencode(json, opts)
  %
  % :param json: JSON structure
  % :type json: structure
  %
  % :returns: - :S: (string) serialized JSON structure
  %
  %
  % :param opts: optional parameters
  % :type opts: structure
  %
  %   - ``prettyPrint``: indent output [Default: ``true``]
  %   - ``ReplacementStyle``: string to control how non-alphanumeric
  %                       characters are replaced; [Default: ``'underscore'``]
  %   - ``ConvertInfAndNaN``: encode ``NaN``, ``Inf`` and ``-Inf`` as ``"null"``;
  %                       [Default: ``true``]
  %
  % (C) Copyright 2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % (C) Copyright 2018 BIDS-MATLAB developers

  if ~nargin
    error('Not enough input arguments.');
  else
    [varargout{1:nargout}] = jsonwrite(varargin{:}); % JSONio copy - always exist
  end
