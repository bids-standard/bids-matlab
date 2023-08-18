function test_suite = test_plot_events %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_plot_events_ds101()

  close all;

  data_dir = fullfile(get_test_data_dir(), 'ds001');

  BIDS = bids.layout(data_dir, 'index_dependencies', false);

  events_files = bids.query(BIDS, ...
                            'data', ...
                            'sub', '01', ...
                            'task', 'balloonanalogrisktask', ...
                            'suffix', 'events');

  bids.util.plot_events(events_files);

end

function test_plot_events_ds101_with_model()

  data_dir = fullfile(get_test_data_dir(), 'ds001');

  mode_file = fullfile(get_test_data_dir(), '..', ...
                       'data', ...
                       'model', ...
                       'model-balloonanalogrisktask_smdl.json');

  BIDS = bids.layout(data_dir, 'index_dependencies', false);

  events_files = bids.query(BIDS, ...
                            'data', ...
                            'sub', '01', ...
                            'task', 'balloonanalogrisktask', ...
                            'suffix', 'events');

  bids.util.plot_events(events_files, 'model_file', mode_file);

end

function test_plot_events_ds108()

  data_dir = fullfile(get_test_data_dir(), 'ds108');

  BIDS = bids.layout(data_dir, 'index_dependencies', false);

  events_files = bids.query(BIDS, ...
                            'data', ...
                            'sub', '01', ...
                            'run', '01', ...
                            'suffix', 'events');

  include = 'Reapp_Neg_Cue';
  bids.util.plot_events(events_files, 'include', include);

  include = {'Reapp_Neg_Cue', 'Look_Neg_Cue', 'Look_Neutral_Cue'};
  bids.util.plot_events(events_files, 'include', include);

end
