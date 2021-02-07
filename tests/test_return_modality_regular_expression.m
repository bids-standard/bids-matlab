function test_suite = test_return_modality_regular_expression %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_return_modality_regular_expression_basic

  schema = bids.schema.load_schema();

  regular_expression = bids.internal.return_modality_regular_expression(schema.datatypes.anat(1));

  expected_expression = ['^%s.*', ...
                         '_(T1w|T2w|PDw|T2starw|FLAIR|inplaneT1|inplaneT2|PDT2|angio){1}', ...
                         '(.nii.gz|.nii){1}$'];

  assert(isequal(regular_expression, expected_expression));

  data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'MoAEpilot', 'sub-01', 'anat');
  subject_name = 'sub-01';
  file = bids.internal.file_utils('List', data_dir, sprintf(expected_expression, subject_name));

  assert(isequal(file, 'sub-01_T1w.nii.gz'));

end
