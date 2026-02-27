function test_suite = test_bids_query_nirs %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_emg_basic()
  %
  %   emg queries
  %

  name_n_expected = {
                     % skipping because of
                     % https://github.com/bids-standard/bids-examples/issues/543
                     % 'eyetracking_binocular', 7; ...
                     'eyetracking_fmri', 13 ...
                    };

  for i = 1:size(name_n_expected, 1)
    dataset_name = name_n_expected{i, 1};
    expected_count = name_n_expected{i, 2};
    BIDS = bids.layout(fullfile(get_test_data_dir(), dataset_name), ...
                       'index_dependencies', false);
    files = bids.query(BIDS, 'data');
    assertEqual(numel(files), expected_count);
  end

end
