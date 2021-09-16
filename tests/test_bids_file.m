function test_suite = test_bids_file %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_file_basic()
  bids.File();
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
  input_file = fullfile(pwd, 'sub-01_ses-02_T1w.nii');
  file = bids.File(input_file);
  name_spec.entities.sub = '02';
  % WHEN
  file = file.set_name_spec(name_spec);
  assertEqual(file.suffix, 'T1w');
  assertEqual(file.ext, '.nii');
  assertEqual(file.entities.sub, '02');
  assertEqual(file.entities.ses, '02');
end

function test_bids_filec_input_as_filename()
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
  file = bids.File(fullfile(pwd, 'sub-01_ses-02_run-03_T1w.nii'));
  file.entity_order = {'ses', 'sub'};
  % WHEN
  file = file.reorder_entities();
  % THEN
  assertEqual(file.entities, {'ses'
                              'sub'
                              'run'});
end

function test_bids_file_reorder_entities_schema_based()
  % GIVEN
  file = bids.File(fullfile(pwd, 'sub-01_run-03_T1w.nii'));
  file = file.use_schema();
  name_spec.entities.sub = '02';
  file = file.set_name_spec(name_spec);
  % WHEN
  file = file.reorder_entities();
  % THEN
  assertEqual(file.entities, {'sub'
                              'ses'
                              'run'
                              'acq'
                              'ce'
                              'rec'
                              'part'});
end

function test_bids_file_reorder_entities_user_specified()
  % GIVEN
  file = bids.File(fullfile(pwd, 'sub-01_run-03_T1w.nii'));
  file = file.use_schema();
  % WHEN
  file = file.reorder_entities({'run', 'ses', 'sub'});
  % THEN
  assertEqual(file.entities, {'run'; 'ses'; 'sub'});
end

function test_bids_file_create_filename()
  % GIVEN
  file = bids.File(fullfile(pwd, 'sub-01_ses-02_T1w.nii'));
  name_spec.entities.sub = '02';
  file = file.set_name_spec(name_spec);
  % WHEN
  file = file.create_filename();
  % THEN
  assertEqual(file.filename, 'sub-02_ses-02_T1w.nii');
end

function test_bids_file_get_entity_order()
  % GIVEN
  file = bids.File(fullfile(pwd, 'sub-01_ses-02_T1w.nii'));
  file = file.use_schema();
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
  file = bids.File(fullfile(pwd, 'sub-01_ses-02_T1w.nii'));
  file = file.use_schema();
  % WHEN
  file = file.get_required_entity_from_schema();
  % THEN
  assertEqual(file.required_entities, {'sub'});
end

function test_bids_file_get_modality_from_schema()
  % GIVEN
  file = bids.File(fullfile(pwd, 'sub-01_ses-02_T1w.nii'));
  file = file.use_schema();
  % WHEN
  file = file.get_modality_from_schema();
  % THEN
  assertEqual(file.modality, {'anat'});
end
