function datatypes = find_suffix_datatypes(suffix, schema)
  %
  % For a given suffix, returns all the possible datatypes that have this
  % suffix.
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  datatypes = {};

  if isempty(schema)
    return
  end

  datatypes_list = fieldnames(schema.datatypes);

  for i = 1:size(datatypes_list, 1)

    this_datatype = schema.datatypes.(datatypes_list{i});
    % for CI
    if iscell(this_datatype)
      this_datatype = this_datatype{1};
    end

    suffix_list = cat(1, this_datatype.suffixes);

    if any(ismember(suffix_list, suffix))
      datatypes{end + 1} = datatypes_list{i};
    end

  end

end
