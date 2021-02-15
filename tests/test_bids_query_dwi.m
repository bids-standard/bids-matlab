function test_suite = test_bids_query_dwi %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_dwi_basic()
  %
  %   eeg queries
  %

  pth_bids_example = get_test_data_dir();

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'ds000117'));

  modalities = {'anat',    'beh',    'dwi',    'fmap',    'func',    'meg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'bold', 'dwi', 'events', 'headshape', ...
              'magnitude1', 'magnitude2', 'meg', 'phasediff'};
  % Missing: 'FLASH'
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

end
