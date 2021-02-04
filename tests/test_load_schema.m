function test_load_schema()

  SCHEMA_DIR = fullfile(fileparts(mfilename('fullpath')), 'schema');

  schema = bids.schema.load_schema(SCHEMA_DIR);

  assert(isfield(schema, 'base'));
  assert(isfield(schema, 'subfolder_1'));
  assert(isfield(schema.subfolder_1, 'sub'));
  %     assert(isfield(schema.subfolder_2, 'subfolder_3'));
  %     assert(isfield(schema.subfolder_2.subfolder_3, 'sub'));
  assert(~isfield(schema, 'subfolder_4'));

end
