function extensions = return_datatype_extensions(datatype)

  extensions = '(';

  for iExt = 1:numel(datatype.extensions)
    if ~strcmp(datatype.extensions{iExt}, '.json')
      extensions = [extensions,  datatype.extensions{iExt}, '|']; %#ok<AGROW>
    end
  end

  % Replace final "|" by a "){1}"
  extensions(end:end + 3) = '){1}';

end
