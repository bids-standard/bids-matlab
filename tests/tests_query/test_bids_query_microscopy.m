function test_suite = test_bids_query_microscopy %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_microscopy_basic()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'micr_SEM'));

  BIDS = bids.layout(fullfile(pth_bids_example, 'micr_SPIM'));

  % TODO add query for sample and chunks

end
