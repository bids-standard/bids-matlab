function test_suite = test_return_file_index %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_return_file_index_basic()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, '7t_trt'));

  filename = 'sub-01_ses-1_run-1_magnitude1.nii.gz';

  file_idx = bids.internal.return_file_index(BIDS, 'fmap', filename);

  assertEqual(file_idx, 1);

  filename = 'sub-03_ses-1_T1w.nii.gz';

  file_idx = bids.internal.return_file_index(BIDS, 'anat', filename);

  assertEqual(file_idx, 2);

end

function test_return_file_index_warning()

  skip_if_octave('mixed-string-concat warning thrown');

  pth_bids_example = get_test_data_dir();

  bids_dir = fullfile(pth_bids_example, 'qmri_tb1tfl');

  unindexable_file = fullfile(bids_dir, 'sub-01_task-foo_events.tsv');
  content = struct('onset', 1, 'duration', 1, 'trial_type', 'bar');
  bids.util.tsvwrite(unindexable_file, content);

  assertWarning(@()bids.layout(bids_dir), 'return_file_index:noFileIndex');

  delete(unindexable_file);

end
