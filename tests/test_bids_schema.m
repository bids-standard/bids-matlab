function test_suite = test_bids_schema %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_load()

  use_schema = fullfile(fileparts(mfilename('fullpath')), 'schema');

  schema = bids.schema;
  schema = schema.load(use_schema);

  assert(isfield(schema.content, 'base'));
  assert(isfield(schema.content, 'subfolder_1'));
  assert(isfield(schema.content.subfolder_1, 'sub'));
  assert(~isfield(schema.content, 'subfolder_4'));

  % some recursive aspects are not implemented yet
  %     assert(isfield(schema.subfolder_2, 'subfolder_3'));
  %     assert(isfield(schema.subfolder_2.subfolder_3, 'sub'));

end

function test_schemaless()

  use_schema = false();

  schema = bids.schema;
  schema = schema.load(use_schema);

  assertEqual(schema.content, struct([]));

end

function test_return_datatypes_for_suffix

  schema = bids.schema();
  schema = schema.load();

  datatypes = schema.return_datatypes_for_suffix('bold');

  expected_output = {'func'};

  assertEqual(datatypes, expected_output);

end

function test_return_modality_suffixes_regex

  schema = bids.schema();
  schema = schema.load();

  suffixes = schema.return_modality_suffixes_regex(schema.content.datatypes.func(1));
  assertEqual(suffixes, '_(bold|cbv|sbref){1}');

end

function test_return_modality_extensions_regex

  schema = bids.schema();
  schema = schema.load();

  extensions = schema.return_modality_extensions_regex(schema.content.datatypes.func(1));
  assertEqual(extensions, '(.nii.gz|.nii){1}');

end

function test_return_modality_regex

  schema = bids.schema();
  schema = schema.load();

  regular_expression = schema.return_modality_regex(schema.content.datatypes.anat(1));

  expected_expression = ['^%s.*', ...
                         '_(T1w|T2w|PDw|T2starw|FLAIR|inplaneT1|inplaneT2|PDT2|angio|', ...
                         'T2star|FLASH|PD', ... % deprecated suffixes
                         '){1}', ...
                         '(.nii.gz|.nii){1}$'];

  assertEqual(regular_expression, expected_expression);

  data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'synthetic', 'sub-01', 'anat');
  subject_name = 'sub-01';
  file = bids.internal.file_utils('List', data_dir, sprintf(expected_expression, subject_name));

  assertEqual(file, 'sub-01_T1w.nii.gz');

end

function test_return_entities_for_suffix

  schema = bids.schema();
  schema = schema.load();

  entities = schema.return_entities_for_suffix('bold');

  expected_output = {'sub', 'ses', 'task', 'acq', 'ce', 'rec', 'dir', 'run', 'echo', 'part'};

  assertEqual(entities, expected_output);

end

function test_return_modality_entities_basic

  schema = bids.schema();
  schema = schema.load();

  entities = schema.return_modality_entities(schema.content.datatypes.func(1));

  expected_output = {'sub', 'ses', 'task', 'acq', 'ce', 'rec', 'dir', 'run', 'echo', 'part'};

  assertEqual(entities, expected_output);

end
