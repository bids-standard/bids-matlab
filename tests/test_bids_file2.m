function test_suite = test_bids_file2 %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_parsing()

  filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  file = bids.File2(filename, 'use_schema', false);

  entities = struct('sub', '01', 'ses', 'test', ...
                    'task', 'faceRecognition', 'run', '02');

  assertEqual(file.prefix, 'wua');
  assertEqual(file.suffix, 'bold');
  assertEqual(file.extension, '.nii');
  assertEqual(file.entities, entities);
  assertEqual(file.filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii');
  assertEqual(file.json_filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.json');
  assertEqual(file.bids_path, fullfile('sub-01', 'ses-test'));

  filename = [];
  filename.prefix = 'wua';
  filename.suffix = 'bold';
  filename.ext = '.nii';
  filename.entities = entities;
  file = bids.File2(filename, 'use_schema', false);
  assertEqual(file.filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii');

  % testing empty file name
  file = bids.File2('');
  file.suffix = 'bold';
  file.extension = '.nii';
  assertEqual(file.filename, 'bold.nii');

  file = file.set_entity('sub', 'abc');
  file.suffix = '';
  assertEqual(file.filename, 'sub-abc.nii');

end

function test_change()

  filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  file = bids.File2(filename, 'use_schema', false);

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

function test_bids_file_remove_entities()

  % GIVEN
  filename = 'sub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  file = bids.File2(filename, 'use_schema', false);
  % WHEN
  file.entities.run = '';
  % THEN
  assertEqual(file.filename, 'sub-01_ses-test_task-faceRecognition_bold.nii');

end

function test_reorder()

  filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
  file = bids.File2(filename, 'use_schema', false);
  file = file.reorder_entities({'sub', 'ses'});

  assertEqual(file.entity_order, {'sub'; 'ses'; 'task'; 'run'});
  assertEqual(file.json_filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.json');

end

function test_bids_file_derivatives_2()

  % GIVEN
  filename = 'sub-01_ses-test_T1w.nii';
  file = bids.File2(filename, 'use_schema', false);
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
  file = bids.File2(filename, 'use_schema', false);
  % WHEN
  file.prefix = '';
  file.entities.desc = 'preproc';
  % THEN
  assertEqual(file.filename, 'sub-01_ses-test_task-faceRecognition_run-02_desc-preproc_bold.nii');

end

%% SCHEMA

function test_bids_file_parsing_filename_schema_based()

  % GIVEN
  filename = 'sub-01_task-foo_run-1_bold.nii.gz';
  use_schema = true;

  % WHEN
  file = bids.File2(filename, 'use_schema', use_schema);

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
               'part'});

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
  file = bids.File2(filename, 'use_schema', true);

  % THEN
  assertEqual(file.filename, 'sub-01_task-faceRecognition_run-02_bold.nii');

end

%% ERRORS

function test_error_schema_missing
  
  bf = bids.File2('sub-01_T1w.nii', 'tolerant', false, 'use_schema', false);
  
  % THEN
  assertExceptionThrown(@()bf.get_required_entities(), ...
                        'bids:File2:schemaMissing');

  assertExceptionThrown(@()bf.get_modality_from_schema(), ...
                        'bids:File2:schemaMissing');
                      
  assertExceptionThrown(@()bf.get_entity_order_from_schema(), ...
                        'bids:File2:schemaMissing');                      

end

function test_error_required_entity()
  % GIVEN
  filename.suffix = 'bold';
  filename.ext = '.nii';
  filename.entities = struct( ...
                             'run', '02', ...
                             'acq', '01');
  % THEN
  assertExceptionThrown(@()bids.File2(filename, 'use_schema', true, 'tolerant', false), ...
                        'bids:File2:requiredEntity');

end

function test_error_suffix_in_many_modalities()
  % GIVEN
  filename.suffix = 'events';
  filename.ext = '.tsv';
  filename.entities = struct('sub', '01', ...
                             'task', 'faces');
  % THEN
  assertExceptionThrown(@()bids.File2(filename, 'use_schema', true,  'tolerant', false), ...
                        'bids:File2:manyModalityForsuffix');
end

function test_error_no_extension()
  % GIVEN
  filename.suffix = 'bold';
  filename.entities = struct('sub', '01', ...
                             'task', 'faces');
  % THEN
  assertExceptionThrown(@()bids.File2(filename, 'use_schema', false,  'tolerant', false), ...
                        'bids:File2:emptyExtension');
  assertExceptionThrown(@()bids.File2(filename, 'use_schema', true,  'tolerant', false), ...
                        'bids:File2:emptyExtension');
end

function test_name_validation()
  filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
  assertExceptionThrown(@() bids.File2(filename, 'tolerant', false), ...
                        'bids:File2:prefixDefined');

  filename = 'bold.nii';
  assertExceptionThrown(@() bids.File2(filename, 'tolerant', false), ...
                        'bids:File2:noEntity');

  filename = 'sub-01_task-faceRecognition_ses-test_run-02_bold';
  assertExceptionThrown(@() bids.File2(filename, 'tolerant', false), ...
                        'bids:File2:emptyExtension');

  filename = 'sub-01_task-faceRecognition_ses-test_run-02.nii';
  assertExceptionThrown(@() bids.File2(filename, 'tolerant', false), ...
                        'bids:File2:emptySuffix');
end

function test_error_no_suffix()
  % GIVEN
  filename.entities = struct('sub', '01', ...
                             'task', 'faces');
  % THEN
  assertExceptionThrown(@()bids.File2(filename, 'use_schema', false,  'tolerant', false), ...
                        'bids:File2:emptySuffix');
  assertExceptionThrown(@()bids.File2(filename, 'use_schema', true,  'tolerant', false), ...
                        'bids:File2:emptySuffix');
end

function test_validation()

  bf = bids.File2('sub-01_T1w.nii', 'tolerant', false);

  assertExceptionThrown(@() bf.validate_string([2 3], 'String', '.*'), ...
                        'bids:File2:InvalidString');
  assertExceptionThrown(@() bf.validate_string(['.nii'; '.abc'], 'String', '.*'), ...
                        'bids:File2:InvalidString');
  assertExceptionThrown(@() bf.validate_string('abc', 'String', 'abcde'), ...
                        'bids:File2:InvalidString');

  assertExceptionThrown(@() bf.validate_extension('nii'), ...
                        'bids:File2:InvalidExtension');
  assertExceptionThrown(@() bf.validate_extension('.nii-'), ...
                        'bids:File2:InvalidExtension');
  assertExceptionThrown(@() bf.validate_extension('.nii_'), ...
                        'bids:File2:InvalidExtension');

  assertExceptionThrown(@() bf.validate_prefix('abc/def'), ...
                        'bids:File2:InvalidPrefix');
  assertExceptionThrown(@() bf.validate_prefix('abcsub-def'), ...
                        'bids:File2:InvalidPrefix');

  assertExceptionThrown(@() bf.validate_word('abc/def', 'Word'), ...
                        'bids:File2:InvalidWord');
  assertExceptionThrown(@() bf.validate_word('abc-def', 'Word'), ...
                        'bids:File2:InvalidWord');
end
