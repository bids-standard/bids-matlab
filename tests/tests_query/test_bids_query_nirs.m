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

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'fnirs_tapping'), ...
                     'index_dependencies', false);

  optodes_files = bids.query(BIDS, 'data', ...
                             'suffix', 'optodes');
  assertEqual(numel(optodes_files), 5);

  nirs_files = bids.query(BIDS, 'data', ...
                          'suffix', 'nirs');
  assertEqual(numel(nirs_files), 5);

  metadata = bids.query(BIDS, 'metadata', ...
                        'suffix', 'nirs');
  assertEqual(numel(nirs_files), 5);

  %% dependencies
  dependencies = bids.query(BIDS, 'dependencies', ...
                            'sub', '01', ...
                            'suffix', 'nirs', ...
                            'extension', '.snirf');

  assertEqual(numel(dependencies.group), 3);

  % TODO: cannot query coordsystem file
  coordsystem_files = bids.query(BIDS, 'metadata', ...
                                 'suffix', 'coordsystem');

end
