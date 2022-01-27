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
  BIDS = bids.layout(fullfile(pth_bids_example, 'eeg_face13'));

  modalities = {'eeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'channels', 'eeg', 'electrodes', 'events'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'eeg_ds000117'));

  modalities = {'anat', 'eeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'channels', 'eeg', 'electrodes', 'events'};
  % Missing: 'coordsystem'
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  %% dependencies
  dependencies = bids.query(BIDS, 'dependencies', ...
                            'sub', '01', ...
                            'suffix', 'eeg', ...
                            'run', '1', ...
                            'extension', '.set');

  assertEqual(numel(dependencies.data), 1);
  assertEqual(numel(dependencies.group), 1);

end
