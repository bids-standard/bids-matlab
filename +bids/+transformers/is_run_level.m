function status = is_run_level(data)
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  status = false;

  fields = fieldname(data);

  if ismember(fields, {'onset', 'duration'})
    status = true;
  end

end
