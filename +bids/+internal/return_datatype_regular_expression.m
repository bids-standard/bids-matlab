function regular_expression = return_datatype_regular_expression(datatype)

  suffixes = bids.internal.return_datatype_suffixes(datatype);
  extensions = bids.internal.return_datatype_extensions(datatype);

  regular_expression = ['^%s.*' suffixes extensions '$'];

end
