function test_suite = test_bids_query_fmap %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_query_extension()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, '7t_trt'));

  BIDS.subjects(1).func(1).dependencies.explicit;

  dependencies = bids.query(BIDS, 'dependencies', ...
                            'modality', 'fmap', ...
                            'sub', '01', ...
                            'suffix', 'phasediff', ...
                            'ses', '1', ...
                            'run', '1', ...
                            'extension', '.nii.gz');

  assertEqual(numel(dependencies.group), 2);

  BIDS = bids.layout(fullfile(pth_bids_example, 'hcp_example_bids')); % sub-100307

  BIDS.subjects(1).anat(1).dependencies.explicit;

end
