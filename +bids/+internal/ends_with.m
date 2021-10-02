function res = ends_with(str, pattern)
  %
  % Checks id character array 'str' ends with 'pat'
  %
  % USAGE::
  %
  %   res = bids.internal.endsWith(str, pattern)
  %
  % :param str:
  % :type str: character array
  % :param pattern:
  % :type pattern: character array
  %
  %
  % Based on the equivalent function from SPM12
  %
  % (C) Copyright 2011-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  res = false;
  l_pat = length(pattern);
  if l_pat > length(str)
    return
  end
  res = strcmp(str(end - l_pat + 1:end), pattern);

end
