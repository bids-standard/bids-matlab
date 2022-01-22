function test_suite = test_layout_index_json %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_layout_parse_json()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'qmri_qsm'));

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'modality', 'anat');

  assertEqual(size(data, 1), 2);

  %%
  BIDS = bids.layout(fullfile(pth_bids_example, 'qmri_qsm'), ...
                     'use_schema', false);

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'modality', 'anat');

  assertEqual(size(data, 1), 2);

end
