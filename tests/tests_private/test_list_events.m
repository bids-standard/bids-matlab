function test_suite = test_list_events %#ok<*STOUT>

  close all;

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_list_events_basic()

  pth_bids_example = get_test_data_dir();

  data_sets_to_test = '^ds00[0-9]$'; % '^ds.*[0-9]$'
  examples = bids.internal.file_utils('FPList', get_test_data_dir(), 'dir', data_sets_to_test);

  for i = 1:size(examples, 1)

    BIDS = bids.layout(deblank(examples(i, :)), 'index_dependencies', false);

    tasks = bids.query(BIDS, 'tasks');

    for j = 1:numel(tasks)

      [data, headers, y_labels] = bids.internal.list_events(BIDS, 'func', tasks{j});

      bids.internal.plot_diagnostic_table(data, ...
                                          headers, ...
                                          y_labels, ...
                                          [bids.internal.file_utils(BIDS.pth, 'basename'), ...
                                           ' - ', ...
                                           tasks{j}]);
    end

  end
end
