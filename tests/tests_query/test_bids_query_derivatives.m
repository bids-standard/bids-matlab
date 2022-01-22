function test_suite = test_bids_query_derivatives %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_derivatives_basic()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds000001-fmriprep'), ...
                     'use_schema', false);

  spaces = bids.query(BIDS, 'spaces');
  assertEqual(spaces, {'MNI152NLin2009cAsym', ...
                       'MNI152NLin6Asym', ...
                       'fsaverage5', ...
                       'fsnative'});

  labels = bids.query(BIDS, 'labels');
  assertEqual(labels, {'CSF'    'GM'    'WM'});

  descriptions = bids.query(BIDS, 'descriptions', 'modality', 'func');
  assertEqual(descriptions, {'MELODIC', ...
                             'aparcaseg', ...
                             'aseg', ...
                             'brain', ...
                             'confounds', ...
                             'preproc', ...
                             'smoothAROMAnonaggr'});

  resolutions = bids.query(BIDS, 'resolutions');
  assertEqual(resolutions, {'2'});

end
