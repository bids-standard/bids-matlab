function test_suite = test_return_modality_suffixes %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_return_modality_suffixes_basic

  schema = bids.schema.load_schema();

  suffixes = bids.internal.return_modality_suffixes(schema.datatypes.func(1));
  assert(isequal(suffixes, '_(bold|cbv|sbref){1}'));

end
