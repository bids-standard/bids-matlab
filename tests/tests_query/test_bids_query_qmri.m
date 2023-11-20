function test_suite = test_bids_query_qmri %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_qmri_megre_echos()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'qmri_megre'), ...
                     'index_dependencies', false);

  echos = bids.query(BIDS, 'echos', 'modality', 'anat');
  assertEqual(numel(echos), 8);

end

function test_bids_query_qmri_irt1_inv()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'qmri_irt1'), ...
                     'index_dependencies', false);

  inversions = bids.query(BIDS, 'inversions');
  assertEqual(numel(inversions), 4);

end
