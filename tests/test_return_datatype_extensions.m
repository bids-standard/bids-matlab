function test_return_datatype_extensions

  schema = bids.internal.load_schema();

  extensions = bids.internal.return_datatype_extensions(schema.datatypes.func(1));
  assert(isequal(extensions, '\\(.nii.gz|.nii)'));

end
