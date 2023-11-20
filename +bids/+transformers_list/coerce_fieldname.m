function new_field = coerce_fieldname(field)
  %

  % (C) Copyright 2022 BIDS-MATLAB developers
  new_field = regexprep(field, '[^a-zA-Z0-9_]', '');
  if ~strcmp(new_field, field)
    warning('Field "%s" renamed to "%s"', field, new_field);
  end

end
