function test_suite = test_find_suffix_datatypes %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_find_suffix_datatypes_basic

  schema = bids.schema.load_schema();

  suffix = 'bold';

  datatypes = bids.schema.find_suffix_datatypes(suffix, schema);

  expected_output = {'func'};

  assertEqual(datatypes, expected_output);

end
