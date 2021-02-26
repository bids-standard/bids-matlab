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
  % ---
  %
  % :param opts: structure of optional parameters:
  %                 - Indent: string to use for indentation; [Default: ``''``]
  %                 - ReplacementStyle: string to control how non-alphanumeric
  %                    characters are replaced; [Default: ``'underscore'``]
  %                 - ConvertInfAndNaN: encode ``NaN``, ``Inf`` and ``-Inf`` as ``"null"``;
  %                    [Default: ``true``]
  % :type opts: structure  -
  %

  % Copyright (C) 2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  if ~nargin
    error('Not enough input arguments.');
  end

  persistent has_jsonencode
  if isempty(has_jsonencode)
    has_jsonencode = ...
        exist('jsonencode', 'builtin') == 5 || ... % MATLAB >= R2016b
        ismember(exist('jsonencode', 'file'), [2 3]); % jsonstuff / Matlab-compatible implementation
  end

  if has_jsonencode

    file = '';

    if ischar(varargin{1})
      file = varargin{1};
      varargin(1) = [];
    end

    if numel(varargin) > 1
      opts = varargin{2};
      varargin(2) = [];
      fn   = fieldnames(opts);
      for i = 1:numel(fn)
        if strcmpi(fn{i}, 'ConvertInfAndNaN')
          varargin(2:3) = {'ConvertInfAndNaN', opts.(fn{i})};
        end
      end
    end

    txt = jsonencode(varargin{:});

    if ~isempty(file)
      fid = fopen(file, 'wt');
      if fid == -1
        error('Unable to open file "%s" for writing.', file);
      end
      fprintf(fid, '%s', txt);
      fclose(fid);
    end

    varargout = { txt };

    % JSONio
  elseif exist('jsonwrite', 'file') == 2
    [varargout{1:nargout}] = jsonwrite(varargin{:});

    % SPM12
  elseif exist('spm_jsonwrite', 'file') == 2
    [varargout{1:nargout}] = spm_jsonwrite(varargin{:});

  else
    url = 'https://github.com/gllmflndn/JSONio';
    error('JSON library required: install JSONio from: %s', url);

  end

end
