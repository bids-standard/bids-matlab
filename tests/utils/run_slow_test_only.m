function value = run_slow_test_only()
  % (C) Copyright 2023 BIDS-MATLAB developers
  SLOW = getenv('SLOW');
  value = false;
  if ~isempty(SLOW)
    value = true;
  end
end
