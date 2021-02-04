function subject = append_to_structure(file, subject, modality)
  % Copyright (C) 2021--, BIDS-MATLAB developers

  p = bids.internal.parse_filename(file);
  idx = find_suffix_group(modality, p.type);
  if isempty(idx)
    warning('append_to_structure:noMatchingSuffix', ...
            'Skipping file with no valid suffix in schema: %s', file);
    return
  end

  schema = bids.schema.load_schema();
  entities = bids.schema.return_datatype_entities(schema.datatypes.(modality)(idx));
  p = bids.internal.parse_filename(file, entities);

  if ~isempty(subject.(modality))

    missing_fields = setxor(fieldnames(subject.(modality)), fieldnames(p));

    if ~isempty(missing_fields)
      for iField = 1:numel(missing_fields)
        p = add_missing_field(p, ...
                              missing_fields{iField});
        subject.(modality) = add_missing_field(subject.(modality), ...
                                               missing_fields{iField});
      end
    end

  end

  subject.(modality) = [subject.(modality) p];

end

function structure = add_missing_field(structure, field)
  if ~isfield(structure, field)
    structure.(field) = '';
  end
end

function idx = find_suffix_group(modality, suffix)

  idx = [];

  schema = bids.schema.load_schema();
  suffix_groups = {schema.datatypes.(modality).suffixes}';

  % the following loop could probably be improved with some cellfun magic
  %   cellfun(@(x, y) any(strcmp(x,y)), {p.type}, suffix_groups)
  for i = 1:numel(suffix_groups)
    if any(strcmp(suffix, suffix_groups{i}))
      idx = i;
      break
    end
  end

  if isempty(idx)
    warning('findSuffix:noMatchingSuffix', ...
            'No corresponding suffix in schema for %s for datatype %s', suffix, modality);
  end

end
