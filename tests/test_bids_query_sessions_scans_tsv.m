function test_suite = test_bids_query_sessions_scans_tsv %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

  % Copyright (C) 2019, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2019--, BIDS-MATLAB developers

end

function test_query_sessions_tsv()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, '7t_trt'));

  assert(~isempty(BIDS.subjects(1).sess));
  assert(~isempty(BIDS.subjects(1).scans));


end

function test_query_scans_tsv()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds009'));

  assert(~isempty(BIDS.subjects(1).scans));

end
