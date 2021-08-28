function test_suite = test_bids_init %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_basic()

  dataset_description = fullfile(pwd, 'dummy_ds', 'dataset_description.json');

  bids.init('dummy_ds');
  assertEqual(exist(fullfile(pwd, 'dummy_ds'), 'dir'), 7);

  assertEqual(exist(dataset_description, 'file'), 2);
  ds_metadata = bids.util.jsondecode(dataset_description);
  assertEqual(ds_metadata.DatasetType, 'raw');

  cleanUp();

end

function test_folders()

  folders.subjects = {'01', '02'};
  folders.sessions = {'test', 'retest'};
  folders.modalities = {'anat', 'func'};

  bids.init('dummy_ds', folders);
  assertEqual(exist(fullfile(pwd, 'dummy_ds', 'sub-02', 'ses-retest', 'func'), 'dir'), 7);

  cleanUp();

end

function test_derivatives()

  is_derivative = true;

  folders.subjects = {'01', '02'};
  folders.sessions = {'test', 'retest'};
  folders.modalities = {'anat', 'func'};

  dataset_description = fullfile(pwd, 'dummy_ds', 'dataset_description.json');

  bids.init('dummy_ds', folders, is_derivative);
  assertEqual(exist(fullfile(pwd, 'dummy_ds', 'sub-02', 'ses-retest', 'func'), 'dir'), 7);

  ds_metadata = bids.util.jsondecode(dataset_description);
  assertEqual(ds_metadata.DatasetType, 'derivative');

  % smoke test
  is_datalad_ds = true;
  bids.init('dummy_ds', folders, is_derivative, is_datalad_ds);

  cleanUp();

end

function cleanUp()

  pause(1);

  if is_octave()
    confirm_recursive_rmdir (true, 'local');
  end
  rmdir(fullfile(pwd, 'dummy_ds'), 's');

end
