function string = regexify(string)
  %
  % Turns a string into a simple regex.
  % Useful to query bids dataset with bids.query
  % that by default expects will treat its inputs as regexp.
  %
  %   Input   -->    Output
  %
  %   ``foo`` --> ``^foo$``
  %
  % USAGE::
  %
  %   string = bids.internal.regexify(string)
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  if isempty(string)
    string = '^$';
    return
  end
  if ~strcmp(string(1), '^')
    string = ['^' string];
  end
  if ~strcmp(string(end), '$')
    string = [string '$'];
  end
end
