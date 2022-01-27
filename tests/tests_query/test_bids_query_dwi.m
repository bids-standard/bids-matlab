function test_suite = test_bids_query_dwi %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_dwi_basic()
  %
  %   dwi queries
  %

  pth_bids_example = get_test_data_dir();

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'eeg_rest_fmri'));

  modalities = {'anat',    'dwi',    'eeg', 'func'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'bold', 'dwi', 'eeg'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  dependencies = bids.query(BIDS, 'dependencies', ...
                            'sub', '32', ...
                            'acq', 'NODDI10DIR', ...
                            'suffix', 'dwi', ...
                            'extension', '.nii.gz');

  bval = bids.util.tsvread(dependencies.data{1});
  assertEqual(bval(1:11), [0 repmat(2400, 1, 10)]);

end
