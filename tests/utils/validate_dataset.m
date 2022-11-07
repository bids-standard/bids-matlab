function validate_dataset(bids_path)

  if bids.internal.is_octave && bids.internal.is_github_ci
    return
  end

  [sts, msg] = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders');
  assertEqual(sts, 0);

end
