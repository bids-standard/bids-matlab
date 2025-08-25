function test_suite = test_bids_file %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

%  TODO
% function test_forbidden_order()
%
%   input = 'sub-01_task-nback_ses-02_eeg.bdf';
%   assertExceptionThrown(@() bids.File(input, 'use_schema', true, 'tolerant', false), ...
%                         'bids:File:wrongEntityOrder');
%
% end

function test_no_entity_warning

  skip_if_octave('mixed-string-concat warning thrown');

  assertWarning(@()bids.File('TStatistic.nii', 'verbose', true), ...
                'File:noEntity');

end

function test_no_entity

  bf = bids.File(fullfile(pwd, 'con_0001.niii'));

end

function test_participants

  pth_bids_example = get_test_data_dir();

  file = fullfile(pth_bids_example, 'pet002', 'participants.tsv');

  bf = bids.File(file);

  assertEqual(bf.modality, '');

end

function test_get_metadata_suffixes_basic()
  % ensures that "similar" suffixes are distinguished

  data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'surface_data');

  file = fullfile(data_dir, 'sub-06_hemi-R_space-individual_den-native_thickness.shape.gii');
  side_car = fullfile(data_dir, 'sub-06_hemi-R_space-individual_den-native_thickness.json');

  bf = bids.File(file);

  % TODO only only json file per folder level allowed
  % assertEqual(numel(bf.metadata_files), 1)

  expected_metadata = bids.util.jsondecode(side_car);

  assertEqual(bf.metadata, expected_metadata);

  file = fullfile(data_dir, 'sub-06_hemi-R_space-individual_den-native_midthickness.surf.gii');
  side_car = fullfile(data_dir, 'sub-06_hemi-R_space-individual_den-native_midthickness.json');

  bf = bids.File(file);

  expected_metadata = bids.util.jsondecode(side_car);

  assertEqual(bf.metadata, expected_metadata);

  file = fullfile(data_dir, 'sub-06_space-individual_den-native_thickness.dscalar.nii');
  side_car = fullfile(data_dir, 'sub-06_space-individual_den-native_thickness.json');

  bf = bids.File(file);

  expected_metadata = bids.util.jsondecode(side_car);

  assertEqual(bf.metadata, expected_metadata);

end

function test_metadata_update()
  % Testung updating metadata with metadata_update function
  data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'surface_data');
  file = fullfile(data_dir, 'sub-06_space-individual_den-native_thickness.dscalar.nii');
  bf = bids.File(file);

  % Adding
  bf = bf.metadata_update('Testing', 'adding field');
  assertTrue(isfield(bf.metadata, 'Testing'));
  assertEqual(bf.metadata.Testing, 'adding field');

  % Modifying
  bf = bf.metadata_update('Testing', 'modifying field');
  assertEqual(bf.metadata.Testing, 'modifying field');

  % Removing
  bf = bf.metadata_update('Testing', []);
  assertFalse(isfield(bf.metadata, 'Testing'));
end

function test_metadata_add()
  data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'surface_data');
  file = fullfile(data_dir, 'sub-06_space-individual_den-native_thickness.dscalar.nii');
  bf = bids.File(file);
  bf = bf.metadata_add('Testing', 'adding field');
  assertTrue(isfield(bf.metadata, 'Testing'));
  assertEqual(bf.metadata.Testing, 'adding field');
end

function test_metadata_append()
  data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'surface_data');
  file = fullfile(data_dir, 'sub-06_space-individual_den-native_thickness.dscalar.nii');
  bf = bids.File(file);
  bf = bf.metadata_append('Testing', 'adding field1');
  bf = bf.metadata_append('Testing', 'adding field2');
  assertEqual(bf.metadata.Testing, ...
              {'adding field1'; 'adding field2'});
  % testing char to cell conversion
  bf = bf.metadata_add('Testing2', 1);
  bf = bf.metadata_append('Testing2', 2);
  assertEqual(bf.metadata.Testing2, [1; 2]);
end

function test_metadata_remove()
  data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'surface_data');
  file = fullfile(data_dir, 'sub-06_space-individual_den-native_thickness.dscalar.nii');
  bf = bids.File(file);
  bf = bf.metadata_add('Testing', 'adding field');
  assertTrue(isfield(bf.metadata, 'Testing'));
  bf = bf.metadata_remove('Testing');
  assertFalse(isfield(bf.metadata, 'Testing'));
end

function test_metadata_write()
  data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'surface_data');
  file = fullfile(data_dir, 'sub-06_space-individual_den-native_thickness.dscalar.nii');
  bf = bids.File(file);

  % Writing metadata
  bf.prefix = 'test_';
  out_file = bf.metadata_write();
  assertTrue(exist(out_file, 'file') > 0);
  exported_metadata = bids.util.jsondecode(out_file);
  assertEqual(bf.metadata, exported_metadata);
  teardown(out_file);

  % Writing modified metadata
  out_file = bf.metadata_write('Testing', 'exporting');
  exported_metadata = bids.util.jsondecode(out_file);
  teardown(out_file);
  assertTrue(isfield(exported_metadata, 'Testing'));
  assertFalse(isfield(bf.metadata, 'Testing'));

  bf = bf.metadata_add('Testing', 'exporting');
  assertEqual(bf.metadata, exported_metadata);
end

function test_rename()

  input_filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  input_file = fullfile(fileparts(mfilename('fullpath')), input_filename);
  output_filename = 'sub-01_ses-test_task-faceRecognition_run-02_desc-preproc_bold.nii';
  output_file = fullfile(fileparts(mfilename('fullpath')), output_filename);

  set_up(input_file);
  teardown(output_file);

  file = bids.File(input_file, 'use_schema', false, 'verbose', false);

  assertEqual(file.path, input_file);

  file.prefix = '';
  file.entities.desc = 'preproc';
  assertEqual(file.filename, output_filename);

  file.rename();
  assertEqual(exist(output_file, 'file'), 0);

  file.rename('dry_run', true);
  assertEqual(exist(output_file, 'file'), 0);

  file = file.rename('dry_run', false);
  assertEqual(exist(input_file, 'file'), 0);
  assertEqual(exist(output_file, 'file'), 2);
  assertEqual(file.path, output_file);

  teardown(output_file);

end

function test_rename_with_spec()

  input_filename = 'wuasub-01_task-faceRecognition_bold.nii';
  output_filename = 'sub-01_task-faceRecognition_label-GM_desc-bold_dseg.json';
  file = bids.File(input_filename, 'use_schema', false);

  spec.prefix = '';
  spec.entities.desc = 'bold';
  spec.entities.label = 'GM';
  spec.suffix = 'dseg';
  spec.ext = '.json';
  spec.entity_order = {'sub', 'task', 'label', 'desc'};

  file = file.rename('spec', spec);
  assertEqual(file.filename, output_filename);

end

function test_rename_spec_with_pt()

  input_filename = 'wuasub-01_task-faceRecognition_bold.nii';
  output_filename = 'sub-01_task-faceRecognition_label-GM_res-1pt5_desc-bold_dseg.json';
  file = bids.File(input_filename, 'use_schema', false);

  spec.prefix = '';
  spec.entities.desc = 'bold';
  spec.entities.res = '1.5';
  spec.entities.label = 'GM';
  spec.suffix = 'dseg';
  spec.ext = '.json';
  spec.entity_order = {'sub', 'task', 'label', 'res', 'desc'};

  file = file.rename('spec', spec);
  assertEqual(file.filename, output_filename);

end

function test_rename_force()

  input_filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  input_file = fullfile(fileparts(mfilename('fullpath')), input_filename);
  output_filename = 'sub-01_ses-test_task-faceRecognition_run-02_desc-preproc_bold.nii';
  output_file = fullfile(fileparts(mfilename('fullpath')), output_filename);

  set_up(input_file);
  set_up(output_file);

  system(sprintf('touch %s', input_file));
  system(sprintf('touch %s', output_file));
  file = bids.File(input_file, 'use_schema', false, 'verbose', false);

  assertEqual(file.path, input_file);

  file.prefix = '';
  file.entities.desc = 'preproc';
  file.verbose = true;
  if bids.internal.is_github_ci && ~bids.internal.is_octave
    % failure: warning 'Octave:mixed-string-concat' was raised, expected 'File:fileAlreadyExists'.
    assertWarning(@() file.rename('dry_run', false), 'File:fileAlreadyExists');
  end

  file = file.rename('dry_run', false, 'verbose', false);
  assertEqual(exist(input_file, 'file'), 2);
  assertEqual(exist(output_file, 'file'), 2);

  file = file.rename('dry_run', false, 'force', true, 'verbose', false);
  assertEqual(exist(input_file, 'file'), 0);
  assertEqual(exist(output_file, 'file'), 2);

  teardown(input_file);
  teardown(output_file);

end

function test_camel_case()

  filename = 'sub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  file = bids.File(filename, 'use_schema', false);

  file.entities.task = 'test bla';
  assertEqual(file.filename, 'sub-01_ses-test_task-testBla_run-02_bold.nii');

end

function test_invalid_entity()

  % https://github.com/bids-standard/bids-matlab/issues/362

  input.suffix = 'eeg';
  input.ext = '.bdf';
  input.entities.sub = '01';
  input.entities.task = '0-0 .%5';

  bf =  bids.File(input, 'use_schema', false, 'tolerant', false);
  assertEqual(bf.filename, 'sub-01_task-005_eeg.bdf');

end

function test_forbidden_entity()

  input.suffix = 'eeg';
  input.ext = '.bdf';
  input.entities.sub = '01';
  input.entities.task = 'test';
  input.entities.rec = 'stuff';

  assertExceptionThrown(@() bids.File(input, 'use_schema', true, 'tolerant', false), ...
                        'File:forbiddenEntity');

  input = 'sub-01_task-test_rec-stuff_eeg.bdf';
  assertExceptionThrown(@() bids.File(input, 'use_schema', true, 'tolerant', false), ...
                        'File:forbiddenEntity');

end

function test_parsing()

  filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  bf = bids.File(filename, 'use_schema', false);

  entities = struct('sub', '01', 'ses', 'test', ...
                    'task', 'faceRecognition', 'run', '02');

  assertEqual(bf.modality, '');
  assertEqual(bf.prefix, 'wua');
  assertEqual(bf.suffix, 'bold');
  assertEqual(bf.extension, '.nii');
  assertEqual(bf.entities, entities);
  assertEqual(bf.filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii');
  assertEqual(bf.json_filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.json');
  assertEqual(bf.bids_path, fullfile('sub-01', 'ses-test'));

  filename = [];
  filename.prefix = 'wua';
  filename.suffix = 'bold';
  filename.ext = '.nii';
  filename.entities = entities;
  bf = bids.File(filename, 'use_schema', false);
  assertEqual(bf.filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii');

end

function test_modality_parsing()

  bf = bids.File(struct('modality', 'anat'), 'use_schema', false);
  assertEqual(bf.modality, 'anat');

  filename_expected = { ...
                       '', ''; ...
                       'sub-01_task-faceRecognition_bold.nii', ''; ...
                       fullfile('foo', 'participants.tsv'), ''; ...
                       fullfile('sub-01', 'sub-01_scans.tsv'), ...
                       ''; ... % no modality folder
                       fullfile('sub-01', 'anat', 'sub-01_t1w.nii'), 'anat'; ...
                       fullfile('anat', 'sub-01_t1w.nii'), ...
                       ''; ... % no sub folder
                       fullfile('sub-01', 'ses-01', 'anat', 'sub-01_ses-01_t1w.nii'), 'anat'; ...
                       fullfile('ses-01', 'anat', 'sub-01_ses-01_t1w.nii'), ''; ... % no sub folder
                       fullfile('sub-01', 'ses-01', 'anat', 'sub-01_t1w.nii'), ...
                       ''; ... % no ses in filename
                       fullfile('sub-01', 'anat', 'sub-01_ses-01_t1w.nii'), '' ... % no ses folder
                      };

  for i = 1:size(filename_expected, 1)
    bf = bids.File(filename_expected{i, 1}, 'use_schema', false);
    assertEqual(bf.modality, filename_expected{i, 2});
  end

end

function test_parsing_empty_filename()

  bf = bids.File('');

  bf.suffix = 'bold';
  bf.extension = '.nii';
  assertEqual(bf.filename, 'bold.nii');

  bf = bf.set_entity('sub', 'abc');
  bf.suffix = '';
  assertEqual(bf.filename, 'sub-abc.nii');

end

function test_change()

  filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  file = bids.File(filename, 'use_schema', false);

  % Implicit update
  file.prefix = '';
  file.suffix = 'test';
  assertEqual(file.filename, 'sub-01_ses-test_task-faceRecognition_run-02_test.nii');

  % Explicit update
  file.extension = '.a';
  file = file.update();
  assertEqual(file.filename, 'sub-01_ses-test_task-faceRecognition_run-02_test.a');

  % Setting entities
  file.entities = struct('sub', '02', 'task', 'doNothing', 'acq', 'abc');
  assertEqual(file.bids_path, 'sub-02');
  assertEqual(file.filename, 'sub-02_task-doNothing_acq-abc_test.a');

  file = file.set_entity('task', 'faceRecognition');
  file = file.set_entity('run', '01');
  assertEqual(file.filename, 'sub-02_task-faceRecognition_acq-abc_run-01_test.a');

end

function test_zero_padding

  entities = struct('sub', 1, ...
                    'task', 'faceRecognition', ...
                    'ses', 3, ...
                    'run', 2);
  filename.suffix = 'bold';
  filename.ext = '.nii';
  filename.entities = entities;
  file = bids.File(filename, 'use_schema', true);
  assertEqual(file.filename, 'sub-01_ses-03_task-faceRecognition_run-02_bold.nii');

  file = bids.File(filename, 'use_schema', true, 'padding', 3);
  assertEqual(file.filename, 'sub-001_ses-003_task-faceRecognition_run-002_bold.nii');

  file = bids.File(filename, 'use_schema', true, 'padding', 0);
  assertEqual(file.filename, 'sub-1_ses-3_task-faceRecognition_run-2_bold.nii');

end

function test_zero_padding_spec

  input_filename = 'sub-01_task-faceRecognition_bold.nii';
  file = bids.File(input_filename, 'use_schema', false);

  spec.entities.res = 2;

  file = file.rename('spec', spec);

  output_filename = 'sub-01_task-faceRecognition_res-02_bold.nii';
  assertEqual(file.filename, output_filename);

end

function test_bids_file_remove_entities()

  % GIVEN
  filename = 'sub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  file = bids.File(filename, 'use_schema', false);
  % WHEN
  file.entities.run = '';
  % THEN
  assertEqual(file.filename, 'sub-01_ses-test_task-faceRecognition_bold.nii');

end

function test_reorder()

  filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
  file = bids.File(filename, 'use_schema', false);
  file = file.reorder_entities({'sub', 'ses'});

  assertEqual(file.entity_order, {'sub'; 'ses'; 'task'; 'run'});
  assertEqual(file.json_filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.json');

  filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
  file = bids.File(filename, 'use_schema', false);
  file = file.use_schema();
  file = file.reorder_entities();

  assertEqual(file.entity_order, {'sub'
                                  'ses'; ...
                                  'task'; ...
                                  'acq'; ...
                                  'ce'; ...
                                  'rec'; ...
                                  'dir'; ...
                                  'run'; ...
                                  'echo'; ...
                                  'part'; ...
                                  'chunk'});
  assertEqual(file.json_filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.json');

end

function test_reorder_schemaless()

  filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
  file = bids.File(filename, 'use_schema', false);
  file = file.reorder_entities();
  assertEqual(file.entity_order, {'sub'
                                  'ses'
                                  'sample'
                                  'task'
                                  'tracksys'
                                  'acq'
                                  'nuc'
                                  'voi'
                                  'ce'
                                  'trc'
                                  'stain'
                                  'rec'
                                  'dir'
                                  'run'
                                  'mod'
                                  'echo'
                                  'flip'
                                  'inv'
                                  'mt'
                                  'part'
                                  'proc'
                                  'hemi'
                                  'space'
                                  'split'
                                  'recording'
                                  'chunk'
                                  'seg'
                                  'res'
                                  'den'
                                  'label'
                                  'desc'});
  assertEqual(file.json_filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.json');
end

function test_reorder_schemaless_with_extra_entity()

  filename = 'sub-01_foo-bar_task-face_ses-test_run-02_mask.nii';
  file = bids.File(filename, 'use_schema', false);
  file = file.reorder_entities();
  assertEqual(file.json_filename, 'sub-01_ses-test_task-face_run-02_foo-bar_mask.json');
end

function test_reorder_with_schema()
  filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
  file = bids.File(filename, 'use_schema', true);
  file = file.reorder_entities();
  assertEqual(file.entity_order, {'sub'
                                  'ses'
                                  'task'
                                  'acq'
                                  'ce'
                                  'rec'
                                  'dir'
                                  'run'
                                  'echo'
                                  'part'
                                  'chunk'});
  assertEqual(file.json_filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.json');
end

function test_create_file_with_schema_ignore_extra_entities()
  name_spec.modality = 'fmap';
  name_spec.suffix = 'phasediff';
  name_spec.ext = '.json';
  name_spec.entities = struct('ses', 'test', ...
                              'task', 'face', ...
                              'run', '02', ...
                              'acq', 'low', ...
                              'sub', '01');
  file = bids.File(name_spec, 'use_schema', true);
  assertEqual(file.filename, 'sub-01_ses-test_acq-low_run-02_phasediff.json');
end

function test_create_file_anat()

  name_spec.modality = 'anat';
  name_spec.suffix = 'T1w';
  name_spec.ext = '.json';

  name_spec.entities = struct('ses', '01', ...
                              'acq', 'FullExample', ...
                              'run', '01', ...
                              'sub', '01');

  file = bids.File(name_spec, 'use_schema', true);

  assertEqual(file.filename, 'sub-01_ses-01_acq-FullExample_run-01_T1w.json');

end

function test_create_file_meg()

  name_spec.modality = 'meg';
  name_spec.suffix = 'meg';
  name_spec.ext = '.json';
  name_spec.entities = struct('sub', '01', ...
                              'acq', 'CTF', ...
                              'ses', '01', ...
                              'task', 'FullExample', ...
                              'run', '1', ...
                              'proc', 'sss');

  bids_file = bids.File(name_spec, 'use_schema', true);

  assertEqual(bids_file.filename, 'sub-01_ses-01_task-FullExample_acq-CTF_run-1_proc-sss_meg.json');

end

function test_bids_file_derivatives_2()

  % GIVEN
  filename = 'sub-01_ses-test_T1w.nii';
  file = bids.File(filename, 'use_schema', false);
  % WHEN
  file.modality = 'roi';
  file.suffix = 'mask';
  file.entities.label = 'brain';
  % THEN
  assertEqual(file.filename, 'sub-01_ses-test_label-brain_mask.nii');
  assertEqual(file.bids_path, fullfile('sub-01', 'ses-test', 'roi'));

end

function test_bids_file_derivatives()

  % GIVEN
  filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  file = bids.File(filename, 'use_schema', false);
  % WHEN
  file.prefix = '';
  file.entities.desc = 'preproc';
  % THEN
  assertEqual(file.filename, 'sub-01_ses-test_task-faceRecognition_run-02_desc-preproc_bold.nii');

end

function test_with_plus_in_label()

  filename = 'sub-01_task-faceRecognition_acq-foo+bar_bold.nii';

  bf = bids.File(filename, 'use_schema', true);
  assertEqual(bf.entities.acq, 'foo+bar');
  assertEqual(bf.filename, filename);

  bf = bids.File(filename, 'use_schema', false);
  assertEqual(bf.entities.acq, 'foo+bar');
  assertEqual(bf.filename, filename);

  bf.entities.desc = 'brain+cerebellum';
  assertEqual(bf.filename, ...
              'sub-01_task-faceRecognition_acq-foo+bar_desc-brain+cerebellum_bold.nii');

end

%% SCHEMA

function test_bids_file_parsing_filename_schema_based()

  % GIVEN
  filename = 'sub-01_task-foo_run-1_bold.nii.gz';
  use_schema = true;

  % WHEN
  file = bids.File(filename, 'use_schema', use_schema);

  % THEN
  assert(~isempty(file.schema));
  assertEqual(file.modality, 'func');
  assertEqual(file.entity_required, {'sub', 'task'});
  assertEqual(file.entity_order, ...
              {'sub'
               'ses'
               'task'
               'acq'
               'ce'
               'rec'
               'dir'
               'run'
               'echo'
               'part'
               'chunk'});

  assertEqual(file.prefix, '');
  assertEqual(file.suffix, 'bold');
  assertEqual(file.extension, '.nii.gz');
  assertEqual(file.entities, struct('sub', '01', 'task', 'foo', 'run', '1'));
  assertEqual(file.filename, 'sub-01_task-foo_run-1_bold.nii.gz');
  assertEqual(file.json_filename, 'sub-01_task-foo_run-1_bold.json');
  assertEqual(file.bids_path, fullfile('sub-01', 'func'));

end

function test_bids_file_parsing_structure_schema_based()
  % entities given in any order, should be reordered according to schema

  % GIVEN
  filename.suffix = 'bold';
  filename.ext = '.nii';
  filename.entities = struct('sub', '01', ...
                             'run', '02', ...
                             'task', 'faceRecognition');

  % WHEN
  file = bids.File(filename, 'use_schema', true);

  % THEN
  assertEqual(file.filename, 'sub-01_task-faceRecognition_run-02_bold.nii');

end

%% ERRORS

function test_error_schema_missing

  bf = bids.File('sub-01_T1w.nii', 'tolerant', false, 'use_schema', false);

  % THEN
  assertExceptionThrown(@()bf.get_required_entities(), ...
                        'File:schemaMissing');

  assertExceptionThrown(@()bf.get_modality_from_schema(), ...
                        'File:schemaMissing');

  assertExceptionThrown(@()bf.get_entity_order_from_schema(), ...
                        'File:schemaMissing');

end

function test_error_required_entity()
  % GIVEN
  filename.suffix = 'bold';
  filename.ext = '.nii';
  filename.entities = struct( ...
                             'run', '02', ...
                             'acq', '01');
  % THEN
  assertExceptionThrown(@()bids.File(filename, 'use_schema', true, 'tolerant', false), ...
                        'File:requiredEntity');

end

function test_error_suffix_in_many_modalities()
  % GIVEN
  filename.suffix = 'events';
  filename.ext = '.tsv';
  filename.entities = struct('sub', '01', ...
                             'task', 'faces');
  % THEN
  assertExceptionThrown(@()bids.File(filename, 'use_schema', true,  'tolerant', false), ...
                        'File:manyModalityForsuffix');
end

function test_error_no_extension()
  % GIVEN
  filename.suffix = 'bold';
  filename.entities = struct('sub', '01', ...
                             'task', 'faces');
  % THEN
  assertExceptionThrown(@()bids.File(filename, 'use_schema', false,  'tolerant', false), ...
                        'File:emptyExtension');
  assertExceptionThrown(@()bids.File(filename, 'use_schema', true,  'tolerant', false), ...
                        'File:emptyExtension');
end

function test_name_validation()
  filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
  assertExceptionThrown(@() bids.File(filename, 'tolerant', false, 'use_schema', true), ...
                        'File:prefixDefined');

  filename = 'bold.nii';
  assertExceptionThrown(@() bids.File(filename, 'tolerant', false), ...
                        'File:noEntity');

  filename = 'sub-01_task-faceRecognition_ses-test_run-02_bold';
  assertExceptionThrown(@() bids.File(filename, 'tolerant', false), ...
                        'File:emptyExtension');

  filename = 'sub-01_task-faceRecognition_ses-test_run-02.nii';
  assertExceptionThrown(@() bids.File(filename, 'tolerant', false), ...
                        'File:emptySuffix');
end

function test_error_no_suffix()
  % GIVEN
  filename.entities = struct('sub', '01', ...
                             'task', 'faces');
  % THEN
  assertExceptionThrown(@()bids.File(filename, 'use_schema', false,  'tolerant', false), ...
                        'File:emptySuffix');
  assertExceptionThrown(@()bids.File(filename, 'use_schema', true,  'tolerant', false), ...
                        'File:emptySuffix');
end

function test_validation()

  bf = bids.File('sub-01_T1w.nii', 'tolerant', false);

  assertExceptionThrown(@() bf.validate_string([2 3], 'String', '.*'), ...
                        'File:InvalidString');
  assertExceptionThrown(@() bf.validate_string(['.nii'; '.abc'], 'String', '.*'), ...
                        'File:InvalidString');
  assertExceptionThrown(@() bf.validate_string('abc', 'String', 'abcde'), ...
                        'File:InvalidString');

  assertExceptionThrown(@() bf.validate_extension('nii'), ...
                        'File:InvalidExtension');
  assertExceptionThrown(@() bf.validate_extension('.nii-'), ...
                        'File:InvalidExtension');
  assertExceptionThrown(@() bf.validate_extension('.nii_'), ...
                        'File:InvalidExtension');

  assertExceptionThrown(@() bf.validate_prefix('abc/def'), ...
                        'File:InvalidPrefix');
  assertExceptionThrown(@() bf.validate_prefix('abcsub-def'), ...
                        'File:InvalidPrefix');

  assertExceptionThrown(@() bf.validate_word('abc/def', 'Word'), ...
                        'File:InvalidWord');
  assertExceptionThrown(@() bf.validate_word('abc-def', 'Word'), ...
                        'File:InvalidWord');
end

function set_up(filename)
  if exist(filename, 'file')
    delete(filename);
  end
  system(sprintf('touch %s', filename));
end

function teardown(filename)
  if exist(filename, 'file')
    delete(filename);
  end
end
