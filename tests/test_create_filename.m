function test_suite = test_create_filename %#ok<*STOUT>

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_create_filename_derivatives_2()

  % check path creation
  filename = 'sub-01_ses-test_T1w.nii';

  p.modality = 'roi';
  p.suffix = 'mask';
  p.entities = struct('desc', 'preproc');
  p.use_schema = false;

  [filename, pth] = bids.create_filename(p, filename);

  assertEqual(filename, 'sub-01_ses-test_desc-preproc_mask.nii');

  assertEqual(pth, fullfile('sub-01', 'ses-test', 'roi'));

end

function test_create_filename_derivatives()

  filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';

  % Create filename
  p.entities = struct('desc', 'preproc');
  p.use_schema = false;

  filename = bids.create_filename(p, filename);

  assertEqual(filename, 'wuasub-01_ses-test_task-faceRecognition_run-02_desc-preproc_bold.nii');

  % Same but remove prefix
  p.prefix = '';

  filename = bids.create_filename(p, filename);

  assertEqual(filename, 'sub-01_ses-test_task-faceRecognition_run-02_desc-preproc_bold.nii');

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

  filename = bids.create_filename(p);

  assertEqual(filename, 'sub-01_run-02_ses-test_task-faceRecognition_bold.nii');

end

function test_create_filename_schema_error()

  p.suffix = 'bold';
  p.ext = '.nii';
  p.entities = struct( ...
                      'run', '02', ...
                      'sub', '01');
  p.use_schema = true;

  assertExceptionThrown( ...
                        @()bids.create_filename(p), ...
                        'bidsMatlab:requiredEntity');

end

function test_create_filename_suffix_in_2_modalitiesd()

  p.suffix = 'm0scan';
  p.ext = '.nii';
  p.entities = struct('sub', '01', ...
                      'dir', 'ap');
  p.modality = 'fmap';
  p.use_schema = true;

  [filename, pth] = bids.create_filename(p);

  assertEqual(filename, 'sub-01_dir-ap_m0scan.nii');

  assertEqual(pth, fullfile('sub-01', 'fmap'));

  clear p;

  p.suffix = 'm0scan';
  p.ext = '.nii';
  p.entities = struct('sub', '01');
  p.use_schema = true;

  assertExceptionThrown( ...
                        @()bids.create_filename(p), ...
                        'bidsMatlab:manyModalityForsuffix');

end

function test_create_filename_schema_based()

  p.suffix = 'bold';
  p.ext = '.nii';
  p.entities = struct( ...
                      'run', '02', ...
                      'sub', '01', ...
                      'task', 'face recognition');
  p.use_schema = true;

  filename = bids.create_filename(p);

  assertEqual(filename, 'sub-01_task-faceRecognition_run-02_bold.nii');

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

  [filename, pth] = bids.create_filename(p);

  assertEqual(filename, 'sub-01_ses-test_task-faceRecognition_run-02_bold.nii');
  assertEqual(pth, fullfile('sub-01', 'ses-test', 'func'));

  %% Modify existing filename
  p.entities = struct( ...
                      'sub', '02', ...
                      'task', 'new task');

  filename = bids.create_filename(p, fullfile(pwd, filename));

  assertEqual(filename, 'sub-02_ses-test_task-newTask_run-02_bold.nii');

  %% Remove entity from filename
  p.entities = struct('ses', '');

  filename = bids.create_filename(p, filename);

  assertEqual(filename, 'sub-02_task-newTask_run-02_bold.nii');

end
