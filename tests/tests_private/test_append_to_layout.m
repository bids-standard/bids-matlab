function test_suite = test_append_to_layout %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_layout_missing_subgroup()

  % See https://github.com/bids-standard/bids-matlab/issues/363

  synthetic_derivatives = fullfile(get_test_data_dir(), '..', ...
                                   'data', 'synthetic', 'derivatives', 'manual');

  skip_if_octave('mixed-string-concat warning thrown');

  assertWarning(@()bids.layout(synthetic_derivatives, 'verbose', true), ...
                'append_to_layout:unknownSuffix');

end

function test_append_to_layout_schema_unknown_entity()

  skip_if_octave('mixed-string-concat warning thrown');

  [subject, modality, schema, previous] = set_up('meg');

  file = 'sub-16_task-bar_foo-bar_meg.ds';

  assertWarning(@()bids.internal.append_to_layout(file, subject, modality, schema, previous), ...
                'append_to_layout:unknownEntity');

end

function test_append_to_layout_schema_unknown_extension()

  skip_if_octave('mixed-string-concat warning thrown');

  [subject, modality, schema, previous] = set_up('meg');

  file = 'sub-16_task-bar_meg.foo';

  assertWarning( ...
                @()bids.internal.append_to_layout(file, subject, modality, schema, previous), ...
                'append_to_layout:unknownExtension');

end

function test_append_to_layout_basic()

  [subject, modality, schema, previous] = set_up('anat');

  file = 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  subject = bids.internal.append_to_layout(file, subject, modality, schema, previous);

  expected.anat = struct('filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
                         'suffix', 'T1w', ...
                         'ext', '.nii.gz', ...
                         'prefix', '', ...
                         'entities', struct('sub', '16', ...
                                            'ses', 'mri', ...
                                            'task', '', ...
                                            'run', '1', ...
                                            'acq', 'hd', ...
                                            'ce', '', ...
                                            'rec', '', ...
                                            'echo', '', ...
                                            'part', '', ...
                                            'chunk', ''));

  expected.anat.metafile = {};

  expected.anat.dependencies.explicit = {};
  expected.anat.dependencies.data = {};
  expected.anat.dependencies.group = {};

  fields = fieldnames(expected.anat);
  for i = 1:numel(fields)
    assertEqual(subject.anat.(fields{i}), expected.anat.(fields{i}));
  end
  assertEqual(subject.anat, expected.anat);

end

function test_append_to_layout_schema_missing_required_entity()

  skip_if_octave('mixed-string-concat warning thrown');

  [subject, modality, schema, previous] = set_up('func');

  % func with missing task entity
  file = 'sub-16_bold.nii.gz';

  assertWarning( ...
                @()bids.internal.append_to_layout(file, subject, modality, schema, previous), ...
                'append_to_layout:missingRequiredEntity');

end

function test_append_to_structure_basic_test()

  [subject, modality, schema, previous] = set_up('anat');

  file = 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  [subject, ~, previous] = bids.internal.append_to_layout(file, subject, ...
                                                          modality, schema, previous);

  file = 'sub-16_ses-mri_run-1_T1map.nii.gz';
  subject = bids.internal.append_to_layout(file, subject, ...
                                           modality, schema, previous);

  expected.anat(1, 1) = struct('filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
                               'suffix', 'T1w', ...
                               'ext', '.nii.gz', ...
                               'prefix', '', ...
                               'entities', struct('sub', '16', ...
                                                  'ses', 'mri', ...
                                                  'task', '', ...
                                                  'run', '1', ...
                                                  'acq', 'hd', ...
                                                  'ce', '', ...
                                                  'rec', '', ...
                                                  'echo', '', ...
                                                  'part', '', ...
                                                  'chunk', ''));
  expected.anat(1, 1).metafile = {};

  expected.anat(1, 1).dependencies.explicit = {};
  expected.anat(1, 1).dependencies.data = {};
  expected.anat(1, 1).dependencies.group = {};

  tmp = struct( ...
               'filename', 'sub-16_ses-mri_run-1_T1map.nii.gz', ...
               'suffix', 'T1map', ...
               'ext', '.nii.gz', ...
               'prefix', '', ...
               'entities', struct('sub', '16', ...
                                  'ses', 'mri', ...
                                  'task', '', ...
                                  'run', '1', ...
                                  'acq', '', ...
                                  'ce', '', ...
                                  'rec', '', ...
                                  'chunk', ''));     %#ok<*STRNU>

  tmp.metafile = {};

  tmp.dependencies.explicit = {};
  tmp.dependencies.data = {};
  tmp.dependencies.group = {};

  expected.anat(2, 1) = tmp;

  for i = 1:numel(subject.anat)
    assertEqual(subject.anat(i).filename, expected.anat(i).filename);
    assertEqual(subject.anat(i).ext, expected.anat(i).ext);
    assertEqual(subject.anat(i).entities, expected.anat(i).entities);
  end
  assertEqual(subject.anat, expected.anat);

end

function test_append_to_layout_schemaless()

  use_schema = false;
  [subject, modality, schema, previous] = set_up('newmod', use_schema);

  file = 'sub-16_schema-less_anything-goes_newsuffix.EXT';
  subject = bids.internal.append_to_layout(file, subject, modality, schema, previous);

  expected.newmod = struct( ...
                           'filename', 'sub-16_schema-less_anything-goes_newsuffix.EXT', ...
                           'suffix', 'newsuffix', ...
                           'ext', '.EXT', ...
                           'prefix', '', ...
                           'entities', struct('sub', '16', ...
                                              'schema', 'less', ...
                                              'anything', 'goes'));

  expected.newmod(1, 1).metafile = {};

  expected.newmod(1, 1).dependencies.explicit = {};
  expected.newmod(1, 1).dependencies.data = {};
  expected.newmod(1, 1).dependencies.group = {};

  expected.path = fullfile(pwd, 'sub-01');

  assertEqual(subject, expected);

end

%% Fixture

function [subject, modality, schema, previous] = set_up(modality, use_schema)

  if ~exist('use_schema', 'var')
    use_schema = true;
  end

  schema = bids.Schema(use_schema);
  schema.verbose = true;

  subject = struct(modality, struct([]), ...
                   'path', fullfile(pwd, 'sub-01'));

  previous = struct('group', struct('index', 0, 'base', '', 'len', 1), ...
                    'data', struct('index', 0, 'base', '', 'len', 1), ...
                    'allowed_ext', []);

end
