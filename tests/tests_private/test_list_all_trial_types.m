function test_suite = test_list_all_trial_types %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_list_all_trial_types_basic()

  pth_bids_example = get_test_data_dir();

  BIDS = fullfile(pth_bids_example, 'ds001');

  %% dependencies
  trial_type_list = bids.internal.list_all_trial_types(BIDS, 'balloonanalogrisktask');
  expected = {'cash_demean'; ...
              'control_pumps_demean'; ...
              'explode_demean'; ...
              'pumps_demean'};
  assertEqual(trial_type_list, expected);

end

function test_list_all_trial_types_warning()

  pth_bids_example = get_test_data_dir();

  BIDS = fullfile(pth_bids_example, 'ds001');

  %% dependencies
  trial_type_list = bids.internal.list_all_trial_types(BIDS, {'not', 'a', 'task'}, ...
                                                       'verbose', false);
  assertEqual(trial_type_list, {});

  skip_if_octave('mixed-string-concat warning thrown');

  assertWarning(@() bids.internal.list_all_trial_types(BIDS, {'not', 'a', 'task'}, ...
                                                       'verbose', true), ...
                'list_all_trial_types:noEventsFile');

end

function test_list_all_trial_types_all_numeric()

  pth_bids_example = get_test_data_dir();

  BIDS = fullfile(pth_bids_example, 'ieeg_visual');

  %% dependencies
  trial_type_list = bids.internal.list_all_trial_types(BIDS, {'visual'}, ...
                                                       'verbose', true);
  assertEqual(trial_type_list, {'1'
                                '2'
                                '3'
                                '4'
                                '5'
                                '6'
                                '7'
                                '8'});

end
