function test_suite = test_create_data_dict %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_data_dict_basic()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds001'));

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'suffix', 'events');

  data_dict = bids.util.create_data_dict(data{1}, 'output', 'tmp.json', 'schema', true);

end
