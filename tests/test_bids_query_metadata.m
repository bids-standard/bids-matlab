function test_suite = test_bids_query_metadata %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end


function test_bids_query_metadata_events()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds001'));

  meta = bids.query(BIDS, 'metadata', 'sub', '01', 'run', '01', 'type', 'events');

  assertEqual(fieldnames(meta), {'onset', ...
                                 'duration', ...
                                 'trial_type', ...
                                 'cash_demean', ...
                                 'control_pumps_demean', ...
                                 'explode_demean', ...
                                 'pumps_demean', ...
                                 'response_time'});
                             
end