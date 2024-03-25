function test_suite = test_layout_derivatives %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_layout_modality_same_level_sessions()

  pth_bids_example = fullfile(get_test_data_dir(), ...
                              'synthetic', ...
                              'derivatives', ...
                              'fmriprep');
  tear_down(pth_bids_example);

  BIDS_flat = bids.layout(pth_bids_example, ...
                          'use_schema', false, ...
                          'filter', struct('sub', {{'01', '02', '03'}}), ...
                          'index_dependencies', true);

  % the name won't be accurate
  % because the filenames will still contain the ses entity
  for i = 1:3
    copyfile(fullfile(pth_bids_example, sprintf('sub-%02.0f', i), 'ses-01', 'func'), ...
             fullfile(pth_bids_example, sprintf('sub-%02.0f', i), 'func'));
  end

  BIDS_nested = bids.layout(pth_bids_example, ...
                            'use_schema', false, ...
                            'filter', struct('sub', {{'01', '02', '03'}}), ...
                            'index_dependencies', true);

  assert(numel(bids.query(BIDS_flat, 'data')) < numel(bids.query(BIDS_nested, 'data')));
  assertEqual(numel(bids.query(BIDS_flat, 'data', 'modality', 'anat')), ...
              numel(bids.query(BIDS_nested, 'data', 'modality', 'anat')));
  assertEqual(numel(bids.query(BIDS_flat, 'sessions')), ...
              numel(bids.query(BIDS_nested, 'sessions')));
  assertEqual(numel(bids.query(BIDS_flat, 'subjects')), ...
              numel(bids.query(BIDS_nested, 'subjects')));

  tear_down(pth_bids_example);

  function tear_down(pth_bids_example)
    for j = 1:3
      if exist(fullfile(pth_bids_example, sprintf('sub-%02.0f', j), 'func'), 'dir')
        rmdir(fullfile(pth_bids_example, sprintf('sub-%02.0f', j), 'func'), 's');
      end
    end
  end

end

function test_layout_nested()

  pth_bids_example = get_test_data_dir();

  dataset_to_test = {'ds000117'
                     'qmri_irt1'
                     'qmri_mese'
                     'qmri_mp2rage'
                     'qmri_mp2rageme'
                     'qmri_mtsat'
                     'qmri_sa2rage'
                     'qmri_vfa'
                     'qmri_mpm'};

  for i = 1:numel(dataset_to_test)
    BIDS = bids.layout(fullfile(pth_bids_example, dataset_to_test{i}), ...
                       'use_schema', true, 'tolerant', false, ...
                       'index_derivatives', true, ...
                       'index_dependencies', false);
    fprintf(1, '.');
  end

end

function test_layout_meg_derivatives()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, ...
                              'ds000117', ...
                              'derivatives', ...
                              'meg_derivatives'), ...
                     'use_schema', false, ...
                     'index_dependencies', false);

  modalities = {'meg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'run', '01', ...
                    'proc', 'sss', ...
                    'suffix', 'meg');
  basename = bids.internal.file_utils(data, 'basename');
  assertEqual(basename, {'sub-01_ses-meg_task-facerecognition_run-01_proc-sss_meg'});

end

function test_layout_prefix()

  pth_bids_example = get_test_data_dir();

  copyfile(fullfile(pth_bids_example, 'qmri_tb1tfl', 'sub-01', 'fmap', ...
                    'sub-01_acq-anat_TB1TFL.nii.gz'), ...
           fullfile(pth_bids_example, 'qmri_tb1tfl', 'sub-01', 'fmap', ...
                    'swuasub-01_acq-anat_TB1TFL.nii.gz'));

  BIDS = bids.layout(fullfile(pth_bids_example, 'qmri_tb1tfl'), ...
                     'index_dependencies', false, ...
                     'use_schema', false);

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'prefix', 'swua');
  basename = bids.internal.file_utils(data, 'basename');
  assertEqual(basename, {'swuasub-01_acq-anat_TB1TFL.nii'});

  assertEqual(bids.query(BIDS, 'prefixes'), {'swua'});

  delete(fullfile(pth_bids_example, 'qmri_tb1tfl', 'sub-01', 'fmap', ...
                  'swuasub-01_acq-anat_TB1TFL.nii.gz'));

end

function test_layout_schemaless()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds000001-fmriprep'), ...
                     'index_dependencies', false, ...
                     'use_schema', false);

  modalities = {'anat', 'figures', 'func'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  data = bids.query(BIDS, 'data', ...
                    'sub', '10', ...
                    'modality', 'func', ...
                    'suffix', 'bold', ...
                    'run', '1', ...
                    'res', '2');

  basename = bids.internal.file_utils(data, 'basename');
  assertEqual(basename, {
                         ['sub-10_task-balloonanalogrisktask_run-1', ...
                          '_space-MNI152NLin2009cAsym_res-2_desc-preproc_bold.nii']
                        });

  data = bids.query(BIDS, 'data', ...
                    'sub', '10', ...
                    'modality', 'func', ...
                    'suffix', 'bold', ...
                    'run', '1', ...
                    'space', 'MNI152NLin6Asym');

  basename = bids.internal.file_utils(data, 'basename');
  assertEqual(basename, {
                         ['sub-10_task-balloonanalogrisktask_run-1', ...
                          '_space-MNI152NLin6Asym_desc-smoothAROMAnonaggr_bold.nii']
                        });
end

function test_layout_warning_invalid_subfolder_struct_fieldname()

  % https://github.com/bids-standard/bids-matlab/issues/332

  invalid_subfolder = fullfile(get_test_data_dir(), '..', ...
                               'data', 'synthetic', 'derivatives', 'invalid_subfolder');

  skip_if_octave('mixed-string-concat warning thrown');

  assertWarning(@()bids.layout(invalid_subfolder, ...
                               'use_schema', false, ...
                               'verbose', true), ...
                'layout:invalidSubfolderName');

end
