function test_suite = test_bids_query_nirs %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_nirs_basic()
  %
  %   nirs queries
  %

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'fnirs_tapping'));

  optodes_files = bids.query(BIDS, 'data', ...
                             'suffix', 'optodes');
  assertEqual(numel(optodes_files), 5);

  nirs_files = bids.query(BIDS, 'data', ...
                          'suffix', 'nirs');
  assertEqual(numel(nirs_files), 5);

  metadata = bids.query(BIDS, 'metadata', ...
                        'suffix', 'nirs');
  assertEqual(numel(nirs_files), 5);

  % TODO: cannot query coordsystem file
  coordsystem_files = bids.query(BIDS, 'metadata', ...
                                 'suffix', 'coordsystem');

end
