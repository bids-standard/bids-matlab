function test_suite = test_bids_query_ieeg %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_ieeg_basic()
  %
  %   eeg queries
  %

  pth_bids_example = get_test_data_dir();

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'ieeg_epilepsy'));

  modalities = {'anat', 'ieeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'channels', 'electrodes', 'events', 'ieeg'};
  % Missing: 'coordsystem'
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'ieeg_epilepsy_ecog'));

  modalities = {'anat', 'ieeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'channels', 'electrodes', 'events', 'ieeg', 'photo'};
  % Missing: 'coordsystem'
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

end
