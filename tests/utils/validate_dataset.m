function validate_dataset(bids_path)

  [sts, msg] = bids.validate(bids_path,  '--ignoreNiftiHeaders');
  assert(sts == 0, msg);

end
