function test_suite = test_bids_schema %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end


function test_static()

  assertEqual(bids.Schema_imp.get_version_from_name('schema_entities_v0.0.0.json'),...
              '0.0.0');

  schema_dir = fullfile(bids.internal.root_dir(), 'schema');
  schema_files = bids.internal.file_utils('List', schema_dir,...
                                          '^schema_entities.*\.json$');
  schema_files = cellstr(sortrows(schema_files));

  ver_list = bids.Schema_imp.get_version_list();
  assertEqual(length(ver_list), length(schema_files));

  for i = 1:length(ver_list)
    assertEqual(ver_list{i},...
                bids.Schema_imp.get_version_from_name(schema_files{i}));
  end

  last_ver = bids.Schema_imp.get_last_version();
  assertEqual(schema_files{end}, ['schema_entities_v', last_ver, '.json']);

  assertExceptionThrown(@() bids.Schema_imp.get_schema_path('aaa'), ...
                        'Schema_imp:missingFile');

  path = fullfile(schema_dir, ['schema_entities_v', last_ver, '.json']);
  schema_path = bids.Schema_imp.get_schema_path(last_ver);
  assertEqual(path, schema_path);
end

function  test_loading_json
  ver_list = bids.Schema_imp.get_version_list();
  for i = 1:length(ver_list)
    schema = bids.Schema_imp(ver_list{i}, true);
    assertFalse(isempty(schema.content));
    assertFalse(isempty(schema.modalities));
    assertEqual(schema.version, ver_list{i});
    assertTrue(schema.has_schema());
  end
  schema = bids.Schema_imp('', true);
  assertEqual(schema.version, ver_list{end});

  schema = bids.Schema_imp('', false);
  assertTrue(isempty(schema.content));
  assertTrue(isempty(schema.modalities));
  assertFalse(schema.has_schema());
end

function test_validations
  schema = bids.Schema_imp('1.6.0', true);
  expected_modalities = {'pet'; 'func'; 'meg'; 'dwi'; 'beh';...
                         'anat'; 'fmap'; 'perf'; 'ieeg'; 'eeg'; ...
                         };
  expected_modalities = sort(expected_modalities);
  assertEqual(schema.modalities, expected_modalities);

  % testing random group
  assertTrue(schema.content.isKey('eeg_photo'));
  assertFalse(schema.content.isKey('_eeg_photo_'));
  group = schema.content('eeg_photo');
  assertEqual(group.entities, {'sub'; 'ses'; 'acq'});
  assertEqual(group.extensions, {'.jpg'});
  assertEqual(group.required, {'sub'});

  % testing filename validity based on func_bold
  fname = 'sub-aaa_ses-bbb_task-ccc_acq-ddd_ce-eee_rec-fff_dir-ggg_run-hhh_echo-iii_part-jjj_cbv.nii';
  [res, rules] = schema.test_name(fname, 'func');
  assertTrue(res);
  assertEqual(rules.extensions, {'.nii.gz'; '.nii'; '.json'});
  assertEqual(rules.entities, {'sub'; 'ses'; 'task'; 'acq';...
                               'ce'; 'rec'; 'dir'; 'run';...
                               'echo'; 'part'});
  assertEqual(rules.required, {'sub'; 'task'});
  
  % checking incorrect names
  fname = 'sub-aaa_ses-bb/b_task-ccc_cbv.nii';
  assertExceptionThrown(@() schema.test_name(fname, 'func'),...
                        'Schema_imp:emptyFileStructure');
  fname = 'sub-aaa_ses-bbb_task-ccc_ddd.nii';
  assertExceptionThrown(@() schema.test_name(fname, 'func'),...
                        'Schema_imp:unknownSuffix');
  fname = 'sub-aaa_ses-bbb_task-ccc_bold.xxx';
  assertExceptionThrown(@() schema.test_name(fname, 'func'),...
                        'Schema_imp:unknownExtension');
  fname = 'sub-aaa_ses-bbb_task-ccc_ddd-eee_bold.nii.gz';
  assertExceptionThrown(@() schema.test_name(fname, 'func'),...
                        'Schema_imp:unknownEntity');
  fname = 'sub-aaa_ses-bbb_bold.nii.gz';
  assertExceptionThrown(@() schema.test_name(fname, 'func'),...
                        'Schema_imp:missingRequiredEntity');
end
