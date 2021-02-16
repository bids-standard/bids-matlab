function test_suite = test_bids_query_fmap %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_query_extension()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, '7t_trt'));

  BIDS.subjects(1).fmap(3).intended_for;
  BIDS.subjects(1).func(1).informed_by;

  BIDS = bids.layout(fullfile(pth_bids_example, 'hcp_example_bids')); % sub-100307

  BIDS.subjects(1).fmap(3).intended_for{1};

end
