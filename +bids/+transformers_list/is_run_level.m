function status = is_run_level(data)
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  status = false;

  fields = fieldnames(data);

  if all(ismember({'onset', 'duration'}, fields))
    status = true;
  end

end
