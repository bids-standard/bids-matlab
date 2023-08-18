function test_suite = test_bids_query_eeg %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_eeg_basic_1()
  %
  %   eeg queries
  %

  %%
  BIDS = bids.layout(fullfile(get_test_data_dir, 'eeg_face13'), ...
                     'index_dependencies', false);

  modalities = {'eeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  % Missing: 'coordsystem'
  suffixes = {'channels', 'eeg', 'electrodes', 'events'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  extension = bids.query(BIDS, 'data', 'extension', '.tsv');

  %% dependencies
  dependencies = bids.query(BIDS, 'dependencies', ...
                            'sub', '001', ...
                            'suffix', 'eeg');

  assertEqual(numel(dependencies.group), 3);

end

function test_bids_query_eeg_basic_2()
  %
  %   eeg queries
  %

  %%
  BIDS = bids.layout(fullfile(get_test_data_dir, 'eeg_ds000117'), ...
                     'index_dependencies', false);

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
  assertEqual(numel(dependencies.group), 2);

end
