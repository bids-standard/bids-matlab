function test_query_bug_453()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds000248'), ...
                     'index_dependencies', false);

  assertEqual(bids.query(BIDS, 'modalities'), {'anat', 'meg'});
  assertEqual(bids.query(BIDS, 'modalities', 'task', '.*'), {'meg'});
  assertEqual(bids.query(BIDS, 'modalities', 'task', 'rest'), {});
  assertEqual(bids.query(BIDS, 'modalities', 'task', ''), {'anat'});
  assertEqual(bids.query(BIDS, 'modalities', 'task', []), {'anat'});
  %   assertEqual(bids.query(BIDS, 'modalities', 'task', {'', []}), {'anat'});

  assertEqual(bids.query(BIDS, 'modalities'), {'anat', 'meg'});
  assertEqual(bids.query(BIDS, 'modalities', 'sub', '.*'), {'anat', 'meg'});
  assertEqual(bids.query(BIDS, 'modalities', 'sub', 'notPresent'), {});
  assertEqual(bids.query(BIDS, 'modalities', 'sub', ''), {});
  assertEqual(bids.query(BIDS, 'modalities', 'sub', []), {});
  %   assertEqual(bids.query(BIDS, 'modalities', 'sub', {'', []}), {});

  assertEqual(bids.query(BIDS, 'modalities'), {'anat', 'meg'});
  assertEqual(bids.query(BIDS, 'modalities', 'ses', '.*'), {'meg'});
  assertEqual(bids.query(BIDS, 'modalities', 'ses', 'notPresent'), {});
  assertEqual(bids.query(BIDS, 'modalities', 'ses', ''), {'anat', 'meg'});
  assertEqual(bids.query(BIDS, 'modalities', 'ses', []), {'anat', 'meg'});
  %   assertEqual(bids.query(BIDS, 'modalities', 'ses', {'', []}), {'anat', 'meg'});

end
