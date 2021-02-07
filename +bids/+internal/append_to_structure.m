function subject = append_to_structure(file, subject, modality, schema)
  % Copyright (C) 2021--, BIDS-MATLAB developers

  p = bids.internal.parse_filename(file);
  idx = find_suffix_group(modality, p.suffix, schema);
  if isempty(idx)
    warning('append_to_structure:noMatchingSuffix', ...
            'Skipping file with no valid suffix in schema: %s', file);
    return
  end

  entities = bids.schema.return_modality_entities(schema.datatypes.(modality)(idx));
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
    structure(1).(field) = '';
  end
end

function idx = find_suffix_group(modality, suffix, schema)

  idx = [];

  % the following loop could probably be improved with some cellfun magic
  %   cellfun(@(x, y) any(strcmp(x,y)), {p.type}, suffix_groups)
  for i = 1:size(schema.datatypes.(modality), 1)
    if any(strcmp(suffix, schema.datatypes.(modality)(i).suffixes))
      idx = i;
      break
    end
  end

  if isempty(idx)
    warning('findSuffix:noMatchingSuffix', ...
            'No corresponding suffix in schema for %s for datatype %s', suffix, modality);
  end

end
