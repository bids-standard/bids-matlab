function test_suite = test_bids_file2 %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_validation()
  assertExceptionThrown(@() bids.File2.validate_string([2 3], 'String', '.*'),...
                        'bids:File2:InvalidString');
  assertExceptionThrown(@() bids.File2.validate_string(['.nii'; '.abc'], 'String', '.*'),...
                        'bids:File2:InvalidString');
  assertExceptionThrown(@() bids.File2.validate_string('abc', 'String', 'abcde'),...
                        'bids:File2:InvalidString');
  bids.File2.validate_string('', 'String', '.*');

  assertExceptionThrown(@() bids.File2.validate_extension('nii'),...
                        'bids:File2:InvalidExtension');
  assertExceptionThrown(@() bids.File2.validate_extension('.nii-'),...
                        'bids:File2:InvalidExtension');
  assertExceptionThrown(@() bids.File2.validate_extension('.nii_'),...
                        'bids:File2:InvalidExtension');

  assertExceptionThrown(@() bids.File2.validate_prefix('abc/def'),...
                        'bids:File2:InvalidPrefix');
  assertExceptionThrown(@() bids.File2.validate_prefix('abcsub-def'),...
                        'bids:File2:InvalidPrefix');

  assertExceptionThrown(@() bids.File2.validate_word('abc/def', 'Word'),...
                        'bids:File2:InvalidWord');
  assertExceptionThrown(@() bids.File2.validate_word('abc-def', 'Word'),...
                        'bids:File2:InvalidWord');
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

function test_reorder()
  filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
  file = bids.File2(filename, 'use_schema', false);
  file = file.reorder_entities({'sub', 'ses'});
  assertEqual(file.json_filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.json');
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
