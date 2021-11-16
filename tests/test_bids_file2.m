function test_suite = test_bids_file2 %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_validation()
  assertExceptionThrown(@() bids.File2.validate_string([2 3], 'Error', '.*'), '');
  assertExceptionThrown(@() bids.File2.validate_string(['.nii'; '.abc'], 'Error', '.*'), '');
  assertExceptionThrown(@() bids.File2.validate_string('abc', 'Error', 'abcde'), '');
  bids.File2.validate_string('', 'Error', '.*');

  assertExceptionThrown(@() bids.File2.validate_extension('nii'), '');
  assertExceptionThrown(@() bids.File2.validate_extension('.nii-'), '');
  assertExceptionThrown(@() bids.File2.validate_extension('.nii_'), '');

  assertExceptionThrown(@() bids.File2.validate_prefix('abc/def'), '');
  assertExceptionThrown(@() bids.File2.validate_prefix('abcsub-def'), '');

  assertExceptionThrown(@() bids.File2.validate_word('abc/def', 'Word'), '');
  assertExceptionThrown(@() bids.File2.validate_word('abc-def', 'Word'), '');
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


function test_parsing_no_extension()
    
    % Should this throw at least a warning?
    
    % WHEN
  filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold';
  % WHEN
  file = bids.File2(filename, 'use_schema', false);
  % THEN
  assertEqual(file.extension, '');
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
  
  assertEqual(file.entity_order, {'sub'; 'ses'; 'task'; 'run'});
  assertEqual(file.json_filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.json');
end

function test_reorder_by_property()
    
  % This fails but not sure we want to do things that way anyway
    
  filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
  file = bids.File2(filename, 'use_schema', false);
  file.set_entity_order = {'ses', 'sub', 'task', 'run'};
  file.reorder_entities();
  assertEqual(file.json_filename, 'wuases-test_sub-01_task-faceRecognition_run-02_bold.json');
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

end