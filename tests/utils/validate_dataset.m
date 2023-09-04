function validate_dataset(bids_path)

  if ispc
    return
  end

  [sts, msg] = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders');
  assert(sts == 0, msg);

end
