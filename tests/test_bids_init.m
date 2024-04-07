function test_suite = test_bids_init %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_basic()

  set_test_cfg();

  output_dir = fullfile(temp_dir(), 'dummy_ds');

  bids.init(output_dir);
  assertEqual(exist(output_dir, 'dir'), 7);

  dataset_description = fullfile(output_dir, 'dataset_description.json');
  assertEqual(exist(dataset_description, 'file'), 2);
  ds_metadata = bids.util.jsondecode(dataset_description);
  assertEqual(ds_metadata.DatasetType, 'raw');

end

function test_no_folder_smoke_test()

  set_test_cfg();

  bids.init('dummy_ds', 'folders', struct(), 'is_derivative', true);

end

function test_valid_tsv()
  set_test_cfg();

  output_dir = fullfile(temp_dir(), 'dummy_ds');

  folders.subjects = 'a';
  folders.sessions = '1';
  folders.modalities = 'beh';

  bids.init(output_dir, 'folders', folders);
  assertEqual(exist(fullfile(output_dir, 'sub-a', 'ses-1', 'beh'), 'dir'), 7);
  assertEqual(exist(fullfile(output_dir, 'sub-a', 'sub-a_sessions.tsv'), 'file'), 2);

  participants = bids.util.tsvread(fullfile(output_dir, 'participants.tsv'));
  assertEqual(participants.participant_id, {'sub-a'});

  sessions = bids.util.tsvread(fullfile(output_dir, 'sub-a', 'sub-a_sessions.tsv'));
  assertEqual(sessions.session_id, {'ses-1'});
end

function test_folders()

  set_test_cfg();

  output_dir = fullfile(temp_dir(), 'dummy_ds');

  folders.subjects = {'01', '02'};
  folders.sessions = {'test', 'retest', ''};
  folders.modalities = {'anat', 'func', 'fizz', ''};

  bids.init(output_dir, 'folders', folders);
  assertEqual(exist(fullfile(output_dir, 'sub-02', 'ses-retest', 'func'), 'dir'), 7);
  assertEqual(exist(fullfile(output_dir, 'sub-02', 'sub-02_sessions.tsv'), 'file'), 2);

  sessions = bids.util.tsvread(fullfile(output_dir, 'sub-01', 'sub-01_sessions.tsv'));
  assertEqual(sessions.session_id, {'ses-retest'; 'ses-test'});

end

function test_folders_no_session()

  set_test_cfg();

  output_dir = fullfile(temp_dir(), 'dummy_ds');

  folders.subjects = {'01', '02'};
  folders.modalities = {'anat', 'func'};

  bids.init(output_dir, 'folders', folders);
  assertEqual(exist(fullfile(output_dir, 'sub-02', 'func'), 'dir'), 7);
  assertEqual(exist(fullfile(output_dir, 'sub-02', 'sub-02_sessions.tsv'), 'file'), 0);

  participants = bids.util.tsvread(fullfile(output_dir, 'participants.tsv'));
  assertEqual(participants.participant_id, {'sub-01'; 'sub-02'});

end

function test_validate()

  set_test_cfg();

  output_dir = fullfile(temp_dir(), 'dummy_ds');

  folders.subjects = {'01-bla', '02_foo'};
  folders.sessions = {'te-st', 'ret$est'};
  folders.modalities = {'a#nat', 'fu*nc', '45^['};

  assertExceptionThrown(@() bids.init(output_dir, 'folders', folders), ...
                        'init:nonAlphaNumFodler');

  folders.subjects = {'01', '02'};
  folders.sessions = {'te-st', 'ret$est'};
  folders.modalities = {'a#nat', 'fu*nc', '45^['};

  assertExceptionThrown(@() bids.init(output_dir, 'folders', folders), ...
                        'init:nonAlphaNumFodler');

  folders.subjects = {'01', '02'};
  folders.sessions = {'test', 'retest'};
  folders.modalities = {'a#nat', 'fu*nc', '45^['};

  assertExceptionThrown(@() bids.init(output_dir, 'folders', folders), ...
                        'init:nonAlphaNumFodler');

end

function test_derivatives()

  set_test_cfg();

  output_dir = fullfile(temp_dir(), 'dummy_ds');

  folders.subjects = {'01', '02'};
  folders.sessions = {'test', 'retest'};
  folders.modalities = {'anat', 'func'};

  dataset_description = fullfile(output_dir, 'dataset_description.json');

  bids.init(output_dir, 'folders', folders, 'is_derivative', true);
  assertEqual(exist(fullfile(output_dir, 'sub-02', 'ses-retest', 'func'), 'dir'), 7);

  ds_metadata = bids.util.jsondecode(dataset_description);
  assertEqual(ds_metadata.DatasetType, 'derivative');

  % smoke test
  bids.init(output_dir,  ...
            'folders', folders, ...
            'is_derivative', true, ...
            'is_datalad_ds', true);

end
