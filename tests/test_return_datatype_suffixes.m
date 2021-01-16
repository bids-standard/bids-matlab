function test_return_datatype_suffixes

  schema = bids.internal.load_schema();

  suffixes = bids.internal.return_datatype_suffixes(schema.datatypes.func(1));
  assert(isequal(suffixes, '_(bold|cbv|sbref){1}'));

end
