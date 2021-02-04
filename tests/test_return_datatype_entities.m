function test_suite = test_return_datatype_entities %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_return_datatype_entities_basic

  schema = bids.schema.load_schema();

  entities = bids.schema.return_datatype_entities(schema.datatypes.func(1));

  expected_output = {'sub', 'ses', 'task', 'acq', 'ce', 'rec', 'dir', 'run', 'echo', 'part'};

  assert(isequal(entities, expected_output));

end
