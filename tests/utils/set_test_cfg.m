function cfg = set_test_cfg()

  cfg.verbose = false;
  cfg.use_schema = true;

  if bids.internal.is_octave()
    confirm_recursive_rmdir (false);
  end

end
