function status = is_valid_fieldname(some_str)
  %
  % A valid MATLAB identifier is a character vector of (A-Z, a-z, 0-9) and underscores,
  % such that the first character is a letter and
  % the length of the character vector is less than or equal to namelengthmax.
  %
  % USAGE::
  %
  %     status = is_valid_fieldname(some_str)
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  status = true;

  namelengthmax = 63;

  if ~ischar(some_str)
    status = false;
    return
  end

  if length(some_str) > namelengthmax
    status = false;
    return
  end

  invalid_characters = regexp(some_str, '[^a-zA-Z0-9_]', 'match');
  if ~isempty(invalid_characters)
    status = false;
    return
  end

  invalid_first_characters = regexp(some_str(1), '[^a-zA-Z]', 'match');
  if ~isempty(invalid_first_characters)
    status = false;
    return
  end

end
