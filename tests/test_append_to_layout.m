function test_suite = test_append_to_layout %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_append_to_layout_schema_unknown_entity()

  schema = bids.schema;
  schema = schema.load();
  schema.verbose = true;

  subject = struct('meg', struct([]));

  modality = 'meg';

  % func with missing task entity
  file = '../sub-16/meg/sub-16_task-bar_foo-bar_meg.ds';

  assertWarning( ...
                @()bids.internal.append_to_layout(file, subject, modality, schema), ...
                'append_to_layout:unknownEntity');

end

function test_append_to_layout_schema_unknown_extension()

  schema = bids.schema;
  schema = schema.load();
  schema.verbose = true;

  subject = struct('meg', struct([]));

  modality = 'meg';

  % func with missing task entity
  file = '../sub-16/meg/sub-16_task-bar_meg.foo';

  assertWarning( ...
                @()bids.internal.append_to_layout(file, subject, modality, schema), ...
                'append_to_layout:unknownExtension');

end

function test_append_to_layout_basic()

  schema = bids.schema;
  schema = schema.load();
  schema.verbose = true;

  subject = struct('anat', struct([]));

  modality = 'anat';

  file = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  subject = bids.internal.append_to_layout(file, subject, modality, schema);

  expected.anat = struct( ...
                         'filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
                         'suffix', 'T1w', ...
                         'ext', '.nii.gz', ...
                         'prefix', '', ...
                         'entities', struct('sub', '16', ...
                                            'ses', 'mri', ...
                                            'run', '1', ...
                                            'acq', 'hd', ...
                                            'ce', '', ...
                                            'rec', '', ...
                                            'part', ''));

  assertEqual(subject, expected);

end

function test_append_to_layout_schema_missing_required_entity()

  schema = bids.schema;
  schema = schema.load();
  schema.verbose = true;

  subject = struct('func', struct([]));

  modality = 'func';

  % func with missing task entity
  file = '../sub-16/func/sub-16_bold.nii.gz';

  assertWarning( ...
                @()bids.internal.append_to_layout(file, subject, modality, schema), ...
                'append_to_layout:missingRequiredEntity');

end

function test_append_to_structure_basic_test()

  schema = bids.schema;
  schema = schema.load();

  subject = struct('anat', struct([]));
  modality = 'anat';

  file = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  subject = bids.internal.append_to_layout(file, subject, modality, schema);

  file = '../sub-16/anat/sub-16_ses-mri_run-1_T1map.nii.gz';
  subject = bids.internal.append_to_layout(file, subject, modality, schema);

  expected.anat(1, 1) = struct( ...
                               'filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
                               'suffix', 'T1w', ...
                               'ext', '.nii.gz', ...
                               'prefix', '', ...
                               'entities', struct('sub', '16', ...
                                                  'ses', 'mri', ...
                                                  'run', '1', ...
                                                  'acq', 'hd', ...
                                                  'ce', '', ...
                                                  'rec', '', ...
                                                  'part', ''));

  expected.anat(2, 1) = struct( ...
                               'filename', 'sub-16_ses-mri_run-1_T1map.nii.gz', ...
                               'suffix', 'T1map', ...
                               'ext', '.nii.gz', ...
                               'prefix', '', ...
                               'entities', struct('sub', '16', ...
                                                  'ses', 'mri', ...
                                                  'run', '1', ...
                                                  'acq', '', ...
                                                  'ce', '', ...
                                                  'rec', ''));     %#ok<*STRNU>

  assertEqual(subject, expected);

end

function test_append_to_layout_schemaless()

  use_schema = false;
  schema = bids.schema;
  schema = schema.load(use_schema);

  subject = struct('newmod', struct([]));

  modality = 'newmod';

  file = '../sub-16/newmod/sub-16_schema-less_anything-goes_newsuffix.EXT';
  subject = bids.internal.append_to_layout(file, subject, modality, schema);

  expected.newmod = struct( ...
                           'filename', 'sub-16_schema-less_anything-goes_newsuffix.EXT', ...
                           'suffix', 'newsuffix', ...
                           'ext', '.EXT', ...
                           'prefix', '', ...
                           'entities', struct('sub', '16', ...
                                              'schema', 'less', ...
                                              'anything', 'goes'));

  assertEqual(subject.newmod, expected.newmod);

end
