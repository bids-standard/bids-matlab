function test_suite = test_bids_init %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_basic()

  is_derivative = true;
  is_datalad_ds = true;

  folders.subjects = {'sub-01', 'sub-02'};
  folders.sessions = {'ses-test', 'ses-retest'};
  folders.modalities = {'anat', 'func'};

  bids.init('dummy_ds');
  bids.init('dummy_ds', folders, is_derivative);
  bids.init('dummy_ds', folders, is_derivative, is_datalad_ds);

end
