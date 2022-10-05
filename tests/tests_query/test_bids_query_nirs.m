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

  %% dependencies
  optodes_files = bids.query(BIDS, 'data', ...
                             'suffix', 'optodes');

  assertEqual(numel(optodes_files), 0);

end
