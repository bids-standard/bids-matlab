function test_suite = test_load_schema %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_load_schema_basic()

  SCHEMA_DIR = fullfile(fileparts(mfilename('fullpath')), 'schema');

  schema = bids.schema.load_schema(SCHEMA_DIR);

  assert(isfield(schema, 'base'));
  assert(isfield(schema, 'subfolder_1'));
  assert(isfield(schema.subfolder_1, 'sub'));
  %     assert(isfield(schema.subfolder_2, 'subfolder_3'));
  %     assert(isfield(schema.subfolder_2.subfolder_3, 'sub'));
  assert(~isfield(schema, 'subfolder_4'));

end
