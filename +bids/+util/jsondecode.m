function value = jsondecode(file, varargin)
  %
  % Decode JSON-formatted file
  %
  % USAGE::
  %
  %   json = bids.util.jsondecode(file, opts)
  %
  % :param file: name of a JSON file or JSON string
  % :type file: string
  % :param opts: structure of optional parameters (only with JSONio):
  % :type opts: structure
  %
  % ``opt.replacementStyle``: string to control how non-alphanumeric characters are replaced.
  %
  %    - ``'underscore'`` Default
  %    - ``'hex'``
  %    - ``'delete'``
  %    - ``'nop'``
  %
  %
  % :returns: - :json: JSON structure
  %
  %
  % (C) Copyright 2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  persistent has_jsondecode
  if isempty(has_jsondecode)
    has_jsondecode = ...
        exist('jsondecode', 'builtin') == 5 || ... % MATLAB >= R2016b
        ismember(exist('jsondecode', 'file'), [2 3]); % jsonstuff / Matlab-compatible implementation
  end

  if has_jsondecode
    value = jsondecode(fileread(file));

    % JSONio
  elseif exist('jsonread', 'file') == 3
    value = jsonread(file, varargin{:});

    % SPM12
  elseif exist('spm_jsonread', 'file') == 3
    value = spm_jsonread(file, varargin{:});

  else
    url = 'https://github.com/gllmflndn/JSONio';
    error('JSON library required: install JSONio from: %s', url);
  end

end
