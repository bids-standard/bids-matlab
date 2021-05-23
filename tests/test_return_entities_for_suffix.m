function test_suite = test_return_entities_for_suffix %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_return_entities_for_suffix_basic

  schema = bids.schema.load_schema();

  quiet = true;

  entities = bids.schema.return_entities_for_suffix('bold', schema, quiet);

  expected_output = {'sub', 'ses', 'task', 'acq', 'ce', 'rec', 'dir', 'run', 'echo', 'part'};

  assertEqual(entities, expected_output);

end
