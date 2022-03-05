function file_content = tsvread(filename, field_to_return, hdr)
  %
  % Load text and numeric data from tab-separated-value or other file.
  %
  % USAGE::
  %
  %   file_content = tsvread(filename, field_to_return, hdr)
  %
  % :param filename: filename (can be gzipped) {txt,mat,csv,tsv,json}ename
  % :type filename: string
  % :param field_to_return: name of field to return if data stored in a structure
  %                       [default: ``''``]; or index of column if data stored as an array
  % :type field_to_return:
  % :param hdr: detect the presence of a header row for csv/tsv [default: ``true``]
  % :type hdr: boolean
  %
  %
  % :returns: - :file_content: corresponding data array or structure
  %
  %
  % Based on spm_load.m from SPM12.
  %
  %
  % (C) Copyright 2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  % -Check input arguments
  % --------------------------------------------------------------------------
  if nargin < 1
    error('no input file specified');
  end

  if ~exist(filename, 'file')
    error('Unable to read file ''%s'': file not found', filename);
  end

  if nargin < 2
    field_to_return = '';
  end
  if nargin < 3
    hdr = true;
  end % Detect

  % -Load the data file
  % --------------------------------------------------------------------------
  [~, ~, ext] = fileparts(filename);

  switch ext(2:end)

    case 'txt'
      file_content = load(filename, '-ascii');

    case 'mat'
      file_content = load(filename, '-mat');

    case 'csv'
      % x = csvread(f); % numeric data only
      file_content = dsv_read(filename, ',', hdr);

    case 'tsv'
      % x = dlmread(f,'\t'); % numeric data only
      file_content = dsv_read(filename, '\t', hdr);

    case 'json'
      file_content = bids.util.jsondecode(filename);

    case 'gz'

      if bids.internal.is_octave()
        back_up = tempname;
        copyfile(filename, back_up);
      end
      fz = gunzip(filename, tempname);

      sts = true;
      try
        file_content = bids.util.tsvread(fz{1});
      catch err
        sts = false;
        err_msg = err.message;
      end

      delete(fz{1});
      rmdir(fileparts(fz{1}));

      if bids.internal.is_octave()
        copyfile(back_up, filename);
      end

      if ~sts
        error('Cannot load file ''%s'': %s.', filename, err_msg);
      end

    otherwise
      try
        file_content = load(filename);
      catch
        error('Cannot read file ''%s'': Unknown file format.', filename);
      end

  end

  file_content = return_subset(file_content, field_to_return);

end

function file_content = return_subset(file_content, field_to_return)

  % -Return relevant subset of the data if required
  % --------------------------------------------------------------------------
  if isstruct(file_content)

    if isempty(field_to_return)
      fieldsList = fieldnames(file_content);
      if numel(fieldsList) == 1 && isnumeric(file_content.(fieldsList{1}))
        file_content = file_content.(fieldsList{1});
      end

    else
      if ischar(field_to_return)
        try
          file_content = file_content.(field_to_return);
        catch
          error('Data do not contain array ''%s''.', field_to_return);
        end

      else
        fieldsList = fieldnames(file_content);
        try
          file_content = file_content.(fieldsList{field_to_return});
        catch
          error('Data index out of range: %d (data contains %d fields)', ...
                field_to_return, numel(fieldsList));
        end

      end
    end

  elseif isnumeric(file_content)

    if isnumeric(field_to_return)
      try
        file_content = file_content(:, field_to_return);
      catch
        error('Data index out of range: %d (data contains $d columns).', ...
              field_to_return, size(file_content, 2));
      end

    elseif ~isempty(field_to_return)
      error(['Invalid data index. ', ...
             'When data is numeric, index must be numeric or empty. ', ...
             'Got a %s'], ...
            class(field_to_return));
    end

  end

end

function x = dsv_read(filename, delim, header)

  % Read delimiter-separated values file into a structure array
  % * header line of column names will be used if detected
  % * 'n/a' fields are replaced with NaN

  % -Input arguments
  % --------------------------------------------------------------------------
  if nargin < 2
    delim = '\t';
  end
  if nargin < 3
    header = true;
  end % true: detect, false: no
  delim = sprintf(delim);
  eol = sprintf('\n'); %#ok<SPRINTFN>

  % -Read file
  % --------------------------------------------------------------------------
  S = fileread(filename);
  if isempty(S)
    x = [];
    return
  end
  if S(end) ~= eol
    S = [S eol];
  end
  S = regexprep(S, {'\r\n', '\r', '(\n)\1+'}, {'\n', '\n', '$1'});

  % -Get column names from header line (non-numeric first line)
  % --------------------------------------------------------------------------
  h = find(S == eol, 1);
  hdr = S(1:h - 1);
  var = regexp(hdr, delim, 'split');
  N = numel(var);
  n1 = isnan(cellfun(@str2double, var));
  n2 = cellfun(@(x) strcmpi(x, 'NaN'), var);
  if header && any(n1 & ~n2)
    hdr = true;
    try
      var = genvarname(var); %#ok<DEPGENAM>
    catch
      var = matlab.lang.makeValidName(var, 'ReplacementStyle', 'hex');
      var = matlab.lang.makeUniqueStrings(var);
    end
    S = S(h + 1:end);
  else
    hdr = false;
    fmt = ['Var%0' num2str(floor(log10(N)) + 1) 'd'];
    var = arrayfun(@(x) sprintf(fmt, x), (1:N)', 'UniformOutput', false);
  end

  % -Parse file
  % --------------------------------------------------------------------------
  if exist('OCTAVE_VERSION', 'builtin') % bug #51093
    S = strrep(S, delim, '#');
    delim = '#';
  end
  if ~isempty(S)
    d = textscan(S, '%s', 'Delimiter', delim);
  else
    d = {[]};
  end
  if rem(numel(d{1}), N)
    error('Invalid DSV file ''%s'': Varying number of delimiters per line.', ...
          filename);
  end
  d = reshape(d{1}, N, [])';
  allnum = true;
  for i = 1:numel(var)
    sts = true;
    dd = zeros(size(d, 1), 1);
    for j = 1:size(d, 1)
      if strcmp(d{j, i}, 'n/a')
        dd(j) = NaN;
      else
        dd(j) = str2double(d{j, i}); % i,j considered as complex
        if isnan(dd(j))
          sts = false;
          break
        end
      end
    end
    if sts
      x.(var{i}) = dd;
    else
      x.(var{i}) = d(:, i);
      allnum = false;
    end
  end

  if ~hdr && allnum
    x = struct2cell(x);
    x = [x{:}];
  end

end
