function datatypes = find_suffix_datatypes(suffix, schema)
  %
  % For a given suffix, returns all the possible datatypes that have this
  % suffix.
  %

  datatypes = {};

  if isempty(schema)
    return
  end

  datatypes_list = fieldnames(schema.datatypes);

  for i = 1:size(datatypes_list, 1)

    suffix_list = cat(1, schema.datatypes.(datatypes_list{i}).suffixes);

    if any(ismember(suffix_list, suffix))
      datatypes{end + 1} = datatypes_list{i};
    end

  end

end
