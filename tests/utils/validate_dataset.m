function validate_dataset(bids_path)

  % testing in CI with octave happens through Moxunit action
  % which does not support the bids validator
  if bids.internal.is_octave
    return
  end

  [sts, msg] = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders');
  assertEqual(sts, 0);

end
