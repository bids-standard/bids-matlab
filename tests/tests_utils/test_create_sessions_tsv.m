function test_suite = test_create_sessions_tsv %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_sessions_tsv_no_session()

  bids_path = fullfile(get_test_data_dir(), 'ds210');

  output_filenames = bids.util.create_sessions_tsv(bids_path, 'verbose', false);

  assert(isempty(output_filenames));
  assertEqual(exist(output_filenames, 'file'), 0);

  assertWarning(@() bids.util.create_sessions_tsv(bids_path, 'verbose', true), ...
                'create_sessions_tsv:noSessionInDataset');

end

function test_create_sessions_tsv_basic()

  bids_path = fullfile(get_test_data_dir(), 'ieeg_epilepsy');

  output_filenames = bids.util.create_sessions_tsv(bids_path, 'verbose', true);

  teardown(output_filenames);

end

function teardown(filelist)
  for i = 1:numel(filelist)
    delete(filelist{i});
  end
end
