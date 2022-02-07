function test_suite = test_plot_events %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_plot_events_basic()

  data_dir = fullfile(get_test_data_dir(), 'ds001');

  BIDS = bids.layout(data_dir);

  events_files = bids.query(BIDS, ...
                            'data', ...
                            'sub', '01', ...
                            'task', 'balloonanalogrisktask', ...
                            'suffix', 'events');

  bids.util.plot_events(events_files);

end
