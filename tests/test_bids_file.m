function test_suite = test_bids_file %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_file_basic()

  bids.File();

  file = bids.File(fullfile(pwd, 'sub-01_ses-02_T1w.nii'));

  assertEqual(file.pth, pwd);

  assertEqual(file.suffix, 'T1w');

  assertEqual(file.ext, '.nii');

  assertEqual(file.entities.sub, '01');
  assertEqual(file.entities.ses, '02');

  assertEqual(file.relative_pth, 'sub-01/ses-02');

end

function test_bids_file_reorder_entities_order_specified()

  file = bids.File(fullfile(pwd, 'sub-01_ses-02_run-03_T1w.nii'));
  file.entity_order = {'ses', 'sub'};
  file = file.reorder_entities();
  assertEqual(file.entities, {'ses'
                              'sub'
                              'run'});

end

function test_bids_file_reorder_entities_schema_based()

  file = bids.File(fullfile(pwd, 'sub-01_run-03_T1w.nii'));
  file = file.use_schema();
  file.entities.ses = '02';
  file = file.reorder_entities();
  assertEqual(file.entities, {    'sub'
                              'ses'
                              'run'
                              'acq'
                              'ce'
                              'rec'
                              'part'});

end

function test_bids_file_reorder_entities_user_specified()

  file = bids.File(fullfile(pwd, 'sub-01_run-03_T1w.nii'));
  file = file.use_schema();
  file = file.reorder_entities({'run', 'ses', 'sub'});
  assertEqual(file.entities, {'run'; 'ses'; 'sub'});

end

function test_bids_file_create_filename()

  file = bids.File(fullfile(pwd, 'sub-01_ses-02_T1w.nii'));
  file.entities.sub = '02';

  file = file.create_filename();

  assertEqual(file.filename, 'sub-02_ses-02_T1w.nii');

end

function test_bids_file_get_entity_order()

  file = bids.File(fullfile(pwd, 'sub-01_ses-02_T1w.nii'));
  file = file.use_schema();
  [file, required_entities] = file.get_entity_order_from_schema();

  assertEqual(file.entity_order, {'sub'
                                  'ses'
                                  'run'
                                  'acq'
                                  'ce'
                                  'rec'
                                  'part'});

  assertEqual(required_entities, {'sub'});

end

function test_bids_file_get_modality_from_schema()

  file = bids.File(fullfile(pwd, 'sub-01_ses-02_T1w.nii'));
  file = file.use_schema();
  file = file.get_modality_from_schema();

  assertEqual(file.modality, {'anat'});

end
