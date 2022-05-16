function check_field(field_list, data, field_type, tolerant)
  %
  % check that each fied in field_list is present
  % in the data strucuture
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  if nargin < 4
    tolerant = false;
  end

  available_variables = fieldnames(data);

  available_from_fieldlist = ismember(field_list, available_variables);

  if ~all(available_from_fieldlist)
    field_list = cellstr(field_list);
    msg = sprintf('missing variable(s): "%s"', ...
                  strjoin(field_list(~available_from_fieldlist), '", "'));
    bids.internal.error_handling(mfilename(), ['missing' field_type], msg, tolerant, true);
  end

end
