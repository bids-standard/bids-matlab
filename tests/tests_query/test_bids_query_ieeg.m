function test_suite = test_bids_query_ieeg %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_ieeg_basic_1()
  %
  %   eeg queries
  %

  %%
  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ieeg_epilepsy'), ...
                     'index_dependencies', false);

  modalities = {'anat', 'ieeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'channels', 'electrodes', 'events', 'ieeg', 'scans'};
  % Missing: 'coordsystem'
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  %% dependencies
  dependencies = bids.query(BIDS, 'dependencies', ...
                            'sub', '01', ...
                            'run', '01', ...
                            'suffix', 'ieeg', ...
                            'extension', '.eeg');

  assertEqual(numel(dependencies.group), 4);

end

function test_bids_query_ieeg_basic_2()
  %
  %   eeg queries
  %

  %%
  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ieeg_epilepsy_ecog'), ...
                     'index_dependencies', false);

  modalities = {'anat', 'ieeg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'channels', 'electrodes', 'events', 'ieeg', 'photo', 'scans'};
  % Missing: 'coordsystem'
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  %% dependencies
  dependencies = bids.query(BIDS, 'dependencies', ...
                            'sub', 'ecog01', ...
                            'suffix', 'ieeg', ...
                            'extension', '.eeg');

  assertEqual(numel(dependencies.group), 4);

end
