function test_suite = test_load_schema %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_load_schema_path()

  use_schema = fullfile(fileparts(mfilename('fullpath')), 'schema');

  schema = bids.schema.load_schema(use_schema);

  assert(isfield(schema, 'base'));
  assert(isfield(schema, 'subfolder_1'));
  assert(isfield(schema.subfolder_1, 'sub'));
  assert(~isfield(schema, 'subfolder_4'));

  % some recursive aspects are not implemented yet
  %     assert(isfield(schema.subfolder_2, 'subfolder_3'));
  %     assert(isfield(schema.subfolder_2.subfolder_3, 'sub'));

end

function test_load_schema_schemaless()

  use_schema = false();

  schema = bids.schema.load_schema(use_schema);

  assertEqual(schema, []);

end
