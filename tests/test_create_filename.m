function test_suite = test_create_filename %#ok<*STOUT>
  %
  % Copyright (C) 2021 BIDS-MATLAB developers

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_create_filename_basic()

  %% Create filename
  p.suffix = 'bold';
  p.ext = '.nii';
  p.entities = struct( ...
                      'sub', '01', ...
                      'ses', 'test', ...
                      'task', 'face recognition', ...
                      'run', '02');

  filename = bids.util.create_filename(p);

  assertEqual(filename, 'sub-01_ses-test_task-faceRecognition_run-02_bold.nii');

  %% Modify existing filename
  p.entities = struct( ...
                      'sub', '02', ...
                      'task', 'new task');

  filename = bids.util.create_filename(p, fullfile(pwd, filename));

  assertEqual(filename, 'sub-02_ses-test_task-newTask_run-02_bold.nii');

  %% Remove entity from filename
  p.entities = struct('ses', '');

  filename = bids.util.create_filename(p, filename);

  assertEqual(filename, 'sub-02_task-newTask_run-02_bold.nii');

end

function test_create_filename_order()

  %% Create filename
  p.suffix = 'bold';
  p.ext = '.nii';
  p.entities = struct( ...
                      'sub', '01', ...
                      'ses', 'test', ...
                      'task', 'face recognition', ...
                      'run', '02');
  p.entity_order = {'sub', 'run'};

  filename = bids.util.create_filename(p);

  assertEqual(filename, 'sub-01_run-02_ses-test_task-faceRecognition_bold.nii');

end

function test_create_filename_schema_based()

  p.suffix = 'bold';
  p.ext = '.nii';
  p.entities = struct( ...
                      'run', '02', ...
                      'sub', '01', ...
                      'task', 'face recognition');
  p.use_schema = true;

  filename = bids.util.create_filename(p);

  assertEqual(filename, 'sub-01_task-faceRecognition_run-02_bold.nii');

end

function test_create_filename_schema_error()

  p.suffix = 'bold';
  p.ext = '.nii';
  p.entities = struct( ...
                      'run', '02', ...
                      'sub', '01');
  p.use_schema = true;

  assertExceptionThrown( ...
                        @()bids.util.create_filename(p), ...
                        'bidsMatlab:requiredEntity');

end
