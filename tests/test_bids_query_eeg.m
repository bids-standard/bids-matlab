function test_suite = test_bids_query_eeg %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_eeg_basic()
  %
  %   eeg queries
  %

  pth_bids_example = get_test_data_dir();

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'eeg_cbm'));

  modalities = {'eeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  types = {'channels', 'eeg', 'events'};
  assertEqual(bids.query(BIDS, 'types'), types);

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'eeg_ds000117'));

  modalities = {'anat', 'eeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  types = {'T1w', 'eeg', 'electrodes', 'events'};
  % Missing: 'coordsystem', 'channels'
  assertEqual(bids.query(BIDS, 'types'), types);

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'eeg_face13'));

  modalities = {'eeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  types = {'channels', 'eeg', 'events'};
  % Missing: 'electrodes'
  % skipped as it contains a task entity and thus does not match the schema
  assertEqual(bids.query(BIDS, 'types'), types);

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'eeg_matchingpennies'));

  modalities = {'eeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  types = {'channels', 'eeg', 'events'};
  assertEqual(bids.query(BIDS, 'types'), types);

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'eeg_rishikesh'));

  modalities = {'eeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  types = {'channels', 'eeg', 'events'};
  assertEqual(bids.query(BIDS, 'types'), types);

end
