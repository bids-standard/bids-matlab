function test_suite = test_bids_file %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

%% create filenames

function test_create_filename_basic()

  % GIVEN
  use_schema = true;

  name_spec.suffix = 'bold';
  name_spec.ext = '.nii';
  name_spec.entities = struct( ...
                              'sub', '01', ...
                              'ses', 'test', ...
                              'task', 'face recognition', ...
                              'run', '02');
  % WHEN
  file = bids.File(name_spec, use_schema);

  % THEN
  assertEqual(file.filename, 'sub-01_ses-test_task-faceRecognition_run-02_bold.nii');
  assertEqual(file.relative_pth, fullfile('sub-01', 'ses-test', 'func'));

  %% Modify existing filename
  new_spec.entities = struct( ...
                             'sub', '02', ...
                             'task', 'new task');

  file = file.create_filename(new_spec);

  assertEqual(file.filename, 'sub-02_ses-test_task-newTask_run-02_bold.nii');

  %% Remove entity from filename
  new_spec.entities = struct('ses', '');

  file = file.create_filename(new_spec);

  assertEqual(file.filename, 'sub-02_task-newTask_run-02_bold.nii');

end

%%

function test_bids_file_basic()
  file = bids.File();
  file = file.reorder_entities();
  file = file.get_required_entity_from_schema();
  file = file.create_filename();
end

function test_bids_file_basic_schema()
  use_schema = true;
  file = bids.File('', use_schema);
  file = file.reorder_entities();
  file = file.get_required_entity_from_schema();
  file = file.create_filename();
end

function test_bids_file_set_name_spec()
  % GIVEN
  file = bids.File();
  name_spec = struct('ext', '.nii', ...
                     'suffix', 'T1w', ...
                     'entities', struct('sub', '01', ...
                                        'ses', '02'));
  % WHEN
  file = file.set_name_spec(name_spec);
  % THEN
  assertEqual(file.suffix, 'T1w');
  assertEqual(file.ext, '.nii');
  assertEqual(file.entities.sub, '01');
  assertEqual(file.entities.ses, '02');
end

function test_bids_file_reset_name_spec()
  % GIVEN
  file = set_up();
  name_spec.entities.sub = '02';
  % WHEN
  file = file.set_name_spec(name_spec);
  % THEN
  assertEqual(file.suffix, 'T1w');
  assertEqual(file.ext, '.nii');
  assertEqual(file.entities.sub, '02');
  assertEqual(file.entities.ses, '02');
end

function test_bids_file_input_as_filename()
  % GIVEN
  input_file = fullfile(pwd, 'sub-01_ses-02_T1w.nii');
  % WHEN
  file = bids.File(input_file);
  % THEN
  assertEqual(file.pth, pwd);
  assertEqual(file.suffix, 'T1w');
  assertEqual(file.ext, '.nii');
  assertEqual(file.entities.sub, '01');
  assertEqual(file.entities.ses, '02');
  assertEqual(file.relative_pth, 'sub-01/ses-02');
end

function test_bids_file_input_as_filename_with_schema()
  % GIVEN
  input_file = fullfile(pwd, 'sub-01_ses-02_T1w.nii');
  use_schema = true;
  % WHEN
  file = bids.File(input_file, use_schema);
  % THEN
  assertEqual(file.pth, pwd);
  assertEqual(file.suffix, 'T1w');
  assertEqual(file.ext, '.nii');
  assertEqual(file.entities.sub, '01');
  assertEqual(file.entities.ses, '02');
  assertEqual(file.relative_pth, 'sub-01/ses-02/anat');
  assertEqual(file.entity_order, {'sub'
                                  'ses'
                                  'run'
                                  'acq'
                                  'ce'
                                  'rec'
                                  'part'});
  assertEqual(file.required_entities, {'sub'});
  assertEqual(file.modality, {'anat'});
end

function test_bids_file_basic_input_as_structure()
  % GIVEN
  input_file = struct('ext', '.nii', ...
                      'suffix', 'T1w', ...
                      'entities', struct('sub', '01', ...
                                         'ses', '02'));
  % WHEN
  file = bids.File(input_file);
  % THEN
  assertEqual(file.suffix, 'T1w');
  assertEqual(file.ext, '.nii');
  assertEqual(file.entities.sub, '01');
  assertEqual(file.entities.ses, '02');
  assertEqual(file.relative_pth, 'sub-01/ses-02');
end

function test_bids_file_reorder_entities_order_specified()
  % GIVEN
  input_file = fullfile(pwd, 'sub-01_ses-02_run-03_T1w.nii');
  file = bids.File(input_file);
  file.entity_order = {'ses', 'sub'};
  % WHEN
  file = file.reorder_entities();
  % THEN
  assertEqual(file.entity_order, {'ses'
                                  'sub'
                                  'run'});
  assertEqual(file.entities, struct('ses', '02', 'sub', '01', 'run', '03'));
end

function test_bids_file_reorder_entities_schema_based()
  % GIVEN
  file = set_up_with_schema();
  % WHEN
  file = file.reorder_entities();
  % THEN
  assertEqual(file.entity_order, {'sub'
                                  'ses'
                                  'run'
                                  'acq'
                                  'ce'
                                  'rec'
                                  'part'});
end

function test_bids_file_reorder_entities_user_specified()
  % GIVEN
  file = set_up_with_schema();
  % WHEN
  file = file.reorder_entities({'run', 'ses', 'sub'});
  % THEN
  assertEqual(file.entity_order, {'run'; 'ses'; 'sub'});
  assertEqual(file.entities, struct('ses', '02', 'sub', '01'));
end

function test_bids_file_create_filename()
  % GIVEN
  file = set_up();
  name_spec.entities.sub = '02';
  file = file.set_name_spec(name_spec);
  % WHEN
  file = file.create_filename();
  % THEN
  assertEqual(file.filename, 'sub-02_ses-02_T1w.nii');
end

function test_bids_file_get_entity_order()
  % GIVEN
  file = set_up_with_schema();
  % WHEN
  file = file.get_entity_order_from_schema();
  % THEN
  assertEqual(file.entity_order, {'sub'
                                  'ses'
                                  'run'
                                  'acq'
                                  'ce'
                                  'rec'
                                  'part'});
end

function test_bids_file_get_required_entity()
  % GIVEN
  file = set_up_with_schema();
  % WHEN
  file = file.get_required_entity_from_schema();
  % THEN
  assertEqual(file.required_entities, {'sub'});
end

function test_bids_file_get_modality_from_schema()
  % GIVEN
  file = set_up_with_schema();
  % WHEN
  file = file.get_modality_from_schema();
  % THEN
  assertEqual(file.modality, {'anat'});
end

% Fixtures

function file = set_up()
  input_file = fullfile(pwd, 'sub-01_ses-02_T1w.nii');
  file = bids.File(input_file);
end

function file = set_up_with_schema()
  input_file = fullfile(pwd, 'sub-01_ses-02_T1w.nii');
  use_schema = true;
  file = bids.File(input_file, use_schema);
end
