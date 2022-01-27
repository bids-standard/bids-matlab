function structure = add_missing_field(structure, field)
  %
  % USAGE::
  %
  %   structure = add_missing_field(structure, field)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  if ~isfield(structure, field)
    structure(1).(field) = '';
  end
end
