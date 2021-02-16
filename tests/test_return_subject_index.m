function test_suite = test_return_subject_index %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_return_subject_index_basic()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, '7t_trt'));

  filename = 'sub-01_ses-1_run-1_magnitude1.nii.gz';

  sub_idx = bids.internal.return_subject_index(BIDS, filename);

  assertEqual(sub_idx, 1);

  filename = 'sub-01_ses-2_run-1_magnitude1.nii.gz';

  sub_idx = bids.internal.return_subject_index(BIDS, filename);

  assertEqual(sub_idx, 2);

  % test subject with no session folder
  BIDS = bids.layout(fullfile(pth_bids_example, 'asl002'));

  filename = 'sub-Sub103_asl.nii.gz';

  sub_idx = bids.internal.return_subject_index(BIDS, filename);

  assertEqual(sub_idx, 1);

end
