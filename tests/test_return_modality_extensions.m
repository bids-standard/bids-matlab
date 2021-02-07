function test_suite = test_return_modality_extensions %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_return_modality_extensions_basic

  schema = bids.schema.load_schema();

  extensions = bids.internal.return_modality_extensions(schema.datatypes.func(1));
  assert(isequal(extensions, '(.nii.gz|.nii){1}'));

end
