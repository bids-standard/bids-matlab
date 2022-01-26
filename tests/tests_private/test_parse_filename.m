function test_suite = test_parse_filename %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_parse_filename_warnings()

  if bids.internal.is_octave()
    return
  end

  fields = {};
  tolerant = true;
  verbose = true;

  filename_error = {
                    {'_a_'; ...
                     'sub-01_-02_T1w.nii'},                 'emptyEntity'; ...
                    {'sub-01_ses-_T1w.nii'},                'emptyLabel'; ...
                    {'sub-01-trim_T1w.nii'},                'tooManyDashes'; ...
                    {'test__suffix.nii'; ...
                     'sub-01_T1w_trim.nii'; ...
                     'sub-01_ses-01_run_acq-1pt0_T1w.nii'}, 'missingDash'; ...
                    {'sub-01_s?-01_T1w.nii'; ...
                     'sub-01_ses-b!_T1w.nii'},              'invalidChar'};
  % the invalid characters test still needs to be able to handle "%" on Octave

  for i = 1:size(filename_error, 1)
    for j = 1:numel(filename_error{i, 1})

      assertWarning(@()bids.internal.parse_filename(filename_error{i, 1}{j}, fields, tolerant), ...
                    ['parse_filename:' filename_error{i, 2}]);

      p = bids.internal.parse_filename(filename_error{i, 1}{j}, fields, tolerant);

      assertEqual(p, struct([]));

    end
  end

end

function test_parse_filename_participants()

  filename = 'participants.tsv';
  output = bids.internal.parse_filename(filename);

  expected = struct( ...
                    'filename', 'participants.tsv', ...
                    'suffix', 'participants', ...
                    'entities', struct(), ...
                    'ext', '.tsv', ...
                    'prefix', '');

  assertEqual(output, expected);

end

function test_parse_filename_prefix()

  filename = 'asub-16_task-rest_run-1_bold.nii';
  output = bids.internal.parse_filename(filename);

  expected = struct( ...
                    'filename', 'asub-16_task-rest_run-1_bold.nii', ...
                    'suffix', 'bold', ...
                    'prefix', 'a', ...
                    'ext', '.nii', ...
                    'entities', struct('sub', '16', ...
                                       'task', 'rest', ...
                                       'run', '1'));

  assertEqual(output, expected);

  expectedEntities = fieldnames(expected.entities);
  entities = fieldnames(output.entities);
  assertEqual(entities, expectedEntities);

  % repeated entity
  filename = 'asub-16_task-rest_wsub-1_bold.nii';
  output = bids.internal.parse_filename(filename);

  expected = struct( ...
                    'filename', 'asub-16_task-rest_wsub-1_bold.nii', ...
                    'suffix', 'bold', ...
                    'prefix', 'a', ...
                    'ext', '.nii', ...
                    'entities', struct('sub', '16', ...
                                       'task', 'rest', ...
                                       'wsub', '1'));

  assertEqual(output, expected);

  expectedEntities = fieldnames(expected.entities);
  entities = fieldnames(output.entities);
  assertEqual(entities, expectedEntities);

  % sub containing entity later in the filename
  % NOT SURE THIS IS THE EXPECTED BEHAVIOR
  filename = 'group-ctrl_wsub-1_bold.nii';
  output = bids.internal.parse_filename(filename);

  expected = struct( ...
                    'filename', 'group-ctrl_wsub-1_bold.nii', ...
                    'suffix', 'bold', ...
                    'prefix', 'group-ctrl_w', ...
                    'ext', '.nii', ...
                    'entities', struct('sub', '1'));

  assertEqual(output, expected);

  expectedEntities = fieldnames(expected.entities);
  entities = fieldnames(output.entities);
  assertEqual(entities, expectedEntities);

end

function test_parse_filename_basic()

  filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  output = bids.internal.parse_filename(filename);

  expected = struct( ...
                    'filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
                    'suffix', 'T1w', ...
                    'ext', '.nii.gz', ...
                    'entities', struct('sub', '16', ...
                                       'ses', 'mri', ...
                                       'run', '1', ...
                                       'acq', 'hd'), ...
                    'prefix', '');

  assertEqual(output, expected);

  expectedEntities = fieldnames(expected.entities);
  entities = fieldnames(output.entities);
  assertEqual(entities, expectedEntities);

end

function test_parse_filename_fields()

  filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  fields = {'sub', 'ses', 'run', 'acq', 'ce'};
  output = bids.internal.parse_filename(filename, fields);

  expected = struct( ...
                    'filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
                    'suffix', 'T1w', ...
                    'ext', '.nii.gz', ...
                    'entities', struct('sub', '16', ...
                                       'ses', 'mri', ...
                                       'run', '1', ...
                                       'acq', 'hd', ...
                                       'ce', ''), ...
                    'prefix', '');

  assertEqual(output, expected);

  expectedEntities = fieldnames(expected.entities);
  entities = fieldnames(output.entities);
  assertEqual(entities, expectedEntities);

end

function test_parse_filename_wrong_template()

  filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';

  assertWarning( ...
                @()bids.internal.parse_filename(filename, {'echo'}, false), ...
                'parse_filename:noMatchingTemplate');

end
