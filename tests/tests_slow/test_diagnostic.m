function test_suite = test_diagnostic %#ok<*STOUT>

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_diagnostic_basic()

  if ~run_slow_test_only()
    moxunit_throw_test_skipped_exception('slow test only');
  end

  close all;

  pth_bids_example = get_test_data_dir();

  data_sets_to_test = '^ds10[13579]$'; % '^ds.*[0-9]$'
  examples = bids.internal.file_utils('FPList', get_test_data_dir(), 'dir', data_sets_to_test);

  for i = 1:size(examples, 1)

    BIDS = bids.layout(deblank(examples(i, :)), 'index_dependencies', false);

    diagnostic_table = bids.diagnostic(BIDS, 'output_path', pwd);
    diagnostic_table = bids.diagnostic(BIDS, 'split_by', {'suffix'}, 'output_path', pwd);
    diagnostic_table = bids.diagnostic(BIDS, 'split_by', {'task'}, 'output_path', pwd);
    diagnostic_table = bids.diagnostic(BIDS, 'split_by', {'task', 'suffix'}, 'output_path', pwd);

  end

end
