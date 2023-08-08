function value = jsondecode(file, varargin)
  %
  % Decode JSON-formatted file
  %
  % USAGE::
  %
  %   json = bids.util.jsondecode(file, opts)
  %
  % :param file: name of a JSON file or JSON char
  % :type  file: char
  %
  % :param opts: structure of optional parameters (only with JSONio):
  % :type  opts: structure
  %
  % ``opt.replacementStyle``: char to control how non-alphanumeric characters are replaced.
  %
  %    - ``'underscore'`` Default
  %    - ``'hex'``
  %    - ``'delete'``
  %    - ``'nop'``
  %
  % :returns: - :json: JSON structure
  %
  %

  % (C) Copyright 2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % (C) Copyright 2018 BIDS-MATLAB developers

  persistent has_jsondecode
  if isempty(has_jsondecode)
    has_jsondecode = ...
        exist('jsondecode', 'builtin') == 5 || ... % MATLAB >= R2016b
        ismember(exist('jsondecode', 'file'), [2 3]); % jsonstuff / Matlab-compatible implementation
  end

  if ~exist(file, 'file')
    msg = sprintf('Unable to read file ''%s'': file not found', ...
                  bids.internal.format_path(file));
    bids.internal.error_handling(mfilename(), 'FileNotFound', ...
                                 msg, false);
  end

  if has_jsondecode
    try
      value = jsondecode(fileread(file));
    catch ME
      warning_cannot_read_json(file);
      rethrow(ME);
    end

    % JSONio
  elseif exist('jsonread', 'file') == 3
    try
      value = jsonread(file, varargin{:});
    catch ME
      warning_cannot_read_json(file);
      rethrow(ME);
    end

    % SPM12
  elseif exist('spm_jsonread', 'file') == 3
    try
      value = spm_jsonread(file, varargin{:});
    catch ME
      warning_cannot_read_json(file);
      rethrow(ME);
    end

  else
    url = 'https://github.com/gllmflndn/JSONio';
    error('JSON library required: install JSONio from: %s', url);

  end

end

function warning_cannot_read_json(file)
  msg = sprintf('Could not read file:\n%s', ...
                bids.internal.format_path(file));
  bids.internal.error_handling(mfilename(), 'CannotReadJson', ...
                               msg, true, true);
end
