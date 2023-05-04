function validate_dataset(bids_path)

  if ispc
    return
  end

  [sts, msg] = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders');
  assertEqual(sts, 0);

end
