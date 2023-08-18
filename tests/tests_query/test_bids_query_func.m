function test_suite = test_bids_query_func %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_func_basic()
  %
  %   func queries
  %

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds001'), ...
                     'index_dependencies', false);

  %% dependencies
  dependencies = bids.query(BIDS, 'dependencies', ...
                            'sub', '01', ...
                            'suffix', 'bold', ...
                            'run', '01');

  assertEqual(numel(dependencies.data), 0);
  assertEqual(numel(dependencies.group), 1);

end
