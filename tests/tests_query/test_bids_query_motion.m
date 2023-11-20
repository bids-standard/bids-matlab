function test_suite = test_bids_query_motion %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_motion_basic()
  %
  %   motion queries
  %

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'motion_spotrotation'), ...
                     'index_dependencies', false);

  optodes_files = bids.query(BIDS, 'data', ...
                             'suffix', 'channels');
  assertEqual(numel(optodes_files), 25);

  nirs_files = bids.query(BIDS, 'data', ...
                          'suffix', 'motion');
  assertEqual(numel(nirs_files), 15);

  nirs_files = bids.query(BIDS, 'data', ...
                          'tracksys', 'PhaseSpace', ...
                          'suffix', 'motion');
  assertEqual(numel(nirs_files), 5);

  nirs_files = bids.query(BIDS, 'data', ...
                          'suffix', 'events');
  assertEqual(numel(nirs_files), 10);

  metadata = bids.query(BIDS, 'metadata', ...
                        'suffix', 'motion');
  assertEqual(numel(nirs_files), 10);

end
