function test_suite = test_bids_schema %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_get_datatypes()

  schema = bids.Schema();
  datatypes = schema.get_datatypes();

  assertEqual(sort(fieldnames(datatypes)), sort({'anat', ...
                                                 'beh', ...
                                                 'dwi', ...
                                                 'eeg', ...
                                                 'fmap', ...
                                                 'func', ...
                                                 'ieeg', ...
                                                 'meg', ...
                                                 'micr', ...
                                                 'motion', ...
                                                 'nirs', ...
                                                 'perf', ...
                                                 'pet'})');

  assertEqual(fieldnames(datatypes.func), {    'func'
                                           'phase'
                                           'events__mri'
                                           'timeseries__func'});

end

function test_return_entity_key()

  schema = bids.Schema();
  entity_key = schema.return_entity_key('description');
  assertEqual(entity_key, 'desc');

  assertExceptionThrown(@()schema.return_entity_key('foo'), 'Schema:UnknownEnitity');

end

function test_return_entities_for_suffix_modality()

  schema = bids.Schema();
  [entities, required] = schema.return_entities_for_suffix_modality('bold', 'func');

  expected_entities = {'sub', 'ses', 'task', 'acq', 'ce', 'rec', 'dir', 'run', 'echo', 'part'};
  assertEqual(entities, expected_entities);

  expected_required = {'sub', 'task'};

  assertEqual(required, expected_required);

end

function test_find_suffix_group()

  schema = bids.Schema();
  suffix_group = schema.find_suffix_group('anat', 'T1w');

  assertEqual(suffix_group, 'nonparametric');

end

function test_metadata_get_definition()

  schema = bids.Schema();
  def = schema.get_definition('onset');

  assertEqual(def.name, 'onset');
  assertEqual(def.type, 'number');
  assertEqual(def.unit, 's');

end

function test_metadata_object()

  schema = bids.Schema();
  assert(schema.eq);

end

function test_return_modality_suffixes_regex

  schema = bids.Schema();

  suffix_group = schema.content.rules.datatypes.func.func;
  suffixes = schema.return_modality_suffixes_regex(suffix_group);
  assertEqual(suffixes, '_(bold|cbv|sbref){1}');

end

function test_return_suffix_groups_for_datatype()

  schema = bids.Schema();

  suffix_groups = schema.return_suffix_groups_for_datatype('func');
  assertEqual(suffix_groups, {    'func'
                              'phase'
                              'events__mri'
                              'timeseries__func'});

end

function test_return_datatypes_for_suffix

  schema = bids.Schema();

  datatypes = schema.return_datatypes_for_suffix('bold');
  assertEqual(datatypes, {'func'});

  datatypes = schema.return_datatypes_for_suffix('events');
  expected_output = {'beh', 'eeg', 'func', 'ieeg', 'meg', 'motion', 'nirs', 'pet'};
  assertEqual(sort(datatypes), sort(expected_output));

  datatypes = schema.return_datatypes_for_suffix('m0scan');
  expected_output = {'fmap', 'perf'};
  assertEqual(datatypes, expected_output);

end

function test_return_required_entities

  schema = bids.Schema();

  suffix_group = schema.content.rules.datatypes.func.func;
  required_entities = schema.required_entities_for_suffix_group(suffix_group);

  expected_output = {'sub', 'task'};

  assertEqual(required_entities, expected_output);

end

function test_schemaless()

  use_schema = false();

  schema = bids.Schema(use_schema);

  assertEqual(schema.content, struct([]));

end

function test_return_modality_extensions_regex

  schema = bids.Schema();

  suffix_group = schema.content.rules.datatypes.func.func;
  extensions = schema.return_modality_extensions_regex(suffix_group);
  assertEqual(extensions, '(.nii.gz|.nii){1}');

end

function test_return_modality_regex

  schema = bids.Schema();

  suffix_group = schema.content.rules.datatypes.anat.nonparametric;
  regular_expression = schema.return_modality_regex(suffix_group);

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

function test_return_modality_entities_basic

  schema = bids.Schema();

  suffix_group = schema.content.rules.datatypes.func.func;
  entities = schema.return_entities_for_suffix_group(suffix_group);

  expected_output = {'sub', 'ses', 'task', 'acq', 'ce', 'rec', 'dir', 'run', 'echo', 'part'};

  assertEqual(entities, expected_output);

end

function test_return_entity_order_default

  schema = bids.Schema();

  order = schema.entity_order();

  expected = {'subject'; ...
              'session'; ...
              'sample'; ...
              'task'; ...
              'tracksys'; ...
              'acquisition'; ...
              'ceagent'; ...
              'tracer'; ...
              'stain'; ...
              'reconstruction'; ...
              'direction'; ...
              'run'; ...
              'modality'; ...
              'echo'; ...
              'flip'; ...
              'inversion'; ...
              'mtransfer'; ...
              'part'; ...
              'processing'; ...
              'hemisphere'; ...
              'space'; ...
              'split'; ...
              'recording'; ...
              'chunk'; ...
              'atlas'; ...
              'resolution'; ...
              'density'; ...
              'label'; ...
              'description'};

  assertEqual(order, expected);

end

function test_return_entity_order

  schema = bids.Schema();

  entity_list_to_order = {'description'
                          'run'
                          'subject'};

  order = schema.entity_order(entity_list_to_order);

  expected = {'subject'
              'run'
              'description'};

  assertEqual(order, expected);

end

function test_return_entity_order_new_entity

  schema = bids.Schema();

  %
  order = schema.entity_order('foo');
  assertEqual(order, {'foo'});

  %
  entity_list_to_order = {'description'
                          'run'
                          'foo'
                          'subject'
                          'bar'};

  order = schema.entity_order(entity_list_to_order);

  expected = {'subject'
              'run'
              'description'
              'bar'
              'foo'};
  assertEqual(order, expected);

end

function test_find_suffix_error()

  schema = bids.Schema();
  schema.verbose = true;
  assertWarning(@()schema.find_suffix_group('anat', 'foo'), 'Schema:noMatchingSuffix');

end
