function test_return_datatype_entities

  schema = bids.internal.load_schema();

  entities = bids.internal.return_datatype_entities(schema.datatypes.func(1));

  expected_output = {
                     'sub'
                     'ses'
                     'task'
                     'acq'
                     'ce'
                     'rec'
                     'dir'
                     'run'
                     'echo'
                     'part'};

  assert(isequal(entities, expected_output));

end
