function str = camel_case(str)
  %
  % Removes non alphanumeric characters and uppercase first letter of all
  % words but the first
  %
  % USAGE::
  %
  %   str = camel_case(str)
  %
  % :param str:
  % :type str: string
  %
  % :returns:
  %           :str: (string) returns the input with an upper case for first letter
  %                  for all words but the first one (``camelCase``) and
  %                  removes invalid characters (like spaces).
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  % camel case: upper case for first letter for all words but the first one
  spaceIdx = regexp(str, '[a-zA-Z0-9]*', 'start');
  str(spaceIdx(2:end)) = upper(str(spaceIdx(2:end)));

  % remove invalid characters
  [unvalidCharacters] = regexp(str, '[^a-zA-Z0-9]');
  str(unvalidCharacters) = [];

end
