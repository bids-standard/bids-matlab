function idx = find_suffix_group(modality, suffix, schema, quiet)
  %
  % For a given sufffix and modality, this returns the "suffix group" this
  % suffix belongs to
  %

  idx = [];

  if nargin < 4 || isempty(quiet)
    quiet = true;
  end

  if isempty(schema)
    return
  end

  % the following loop could probably be improved with some cellfun magic
  %   cellfun(@(x, y) any(strcmp(x,y)), {p.type}, suffix_groups)
  for i = 1:size(schema.datatypes.(modality), 1)

    this_suffix_group = schema.datatypes.(modality)(i);

    % for CI
    if iscell(this_suffix_group)
      this_suffix_group = this_suffix_group{1};
    end

    if any(strcmp(suffix, this_suffix_group.suffixes))
      idx = i;
      break
    end

  end

  if isempty(idx) && ~quiet
    warning('findSuffix:noMatchingSuffix', ...
            'No corresponding suffix in schema for %s for datatype %s', suffix, modality);
  end

end
