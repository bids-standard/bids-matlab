function test_suite = test_parse_filename %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
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
                                       'acq', 'hd'));

  assertEqual(output, expected);

end

function test_parse_filename_fields()

  filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  fields = {'sub', 'ses', 'run', 'acq', 'ce', 'rec', 'part'};
  output = bids.internal.parse_filename(filename);

  expected = struct( ...
                    'filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
                    'suffix', 'T1w', ...
                    'ext', '.nii.gz', ...
                    'entities', struct('sub', '16', ...
                                       'ses', 'mri', ...
                                       'run', '1', ...
                                       'acq', 'hd'));

  assertEqual(output, expected);

end

function test_parse_filename_wrong_template()

  filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';

  assertWarning( ...
                @()bids.internal.parse_filename(filename, {'echo'}), ...
                'bidsMatlab:noMatchingTemplate');

end
