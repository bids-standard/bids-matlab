function test_suite = test_bids_init %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_basic()

  set_test_cfg();

  dataset_description = fullfile(pwd, 'dummy_ds', 'dataset_description.json');

  bids.init('dummy_ds');
  assertEqual(exist(fullfile(pwd, 'dummy_ds'), 'dir'), 7);

  assertEqual(exist(dataset_description, 'file'), 2);
  ds_metadata = bids.util.jsondecode(dataset_description);
  assertEqual(ds_metadata.DatasetType, 'raw');

  clean_up();

end

function test_no_folder_smoke_test()

  set_test_cfg();

  bids.init('dummy_ds', 'folders', struct(), 'is_derivative', true);

  clean_up();

end

function test_folders()

  set_test_cfg();

  folders.subjects = {'01', '02'};
  folders.sessions = {'test', 'retest'};
  folders.modalities = {'anat', 'func'};

  bids.init('dummy_ds', 'folders', folders);
  assertEqual(exist(fullfile(pwd, 'dummy_ds', 'sub-02', 'ses-retest', 'func'), 'dir'), 7);

  clean_up();

end

function test_derivatives()

  set_test_cfg();

  folders.subjects = {'01', '02'};
  folders.sessions = {'test', 'retest'};
  folders.modalities = {'anat', 'func'};

  dataset_description = fullfile(pwd, 'dummy_ds', 'dataset_description.json');

  bids.init('dummy_ds', 'folders', folders, 'is_derivative', true);
  assertEqual(exist(fullfile(pwd, 'dummy_ds', 'sub-02', 'ses-retest', 'func'), 'dir'), 7);

  ds_metadata = bids.util.jsondecode(dataset_description);
  assertEqual(ds_metadata.DatasetType, 'derivative');

  % smoke test
  bids.init('dummy_ds',  ...
            'folders', folders, ...
            'is_derivative', true, ...
            'is_datalad_ds', true);

  clean_up();

end

function clean_up()

  pause(0.5);

  rmdir(fullfile(pwd, 'dummy_ds'), 's');

end
