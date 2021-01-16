function suffixes = return_datatype_suffixes(datatype)

  suffixes = '_(';

  for iExt = 1:numel(datatype.suffixes)
    suffixes = [suffixes,  datatype.suffixes{iExt}, '|']; %#ok<AGROW>
  end

  % Replace final "|" by a "){1}"
  suffixes(end:end + 3) = '){1}';

end
