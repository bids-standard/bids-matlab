function value = run_slow_test_only()
  % (C) Copyright 2023 BIDS-MATLAB developers
  global SLOW
  ENV_SLOW = getenv('SLOW');
  value = false;
  if ~isempty(ENV_SLOW) || (~isempty(SLOW) && SLOW)
    value = true;
  end
end
