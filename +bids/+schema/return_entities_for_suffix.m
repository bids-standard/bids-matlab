function [entities, is_required] = return_entities_for_suffix(suffix, schema, quiet)
  %
  % returns the list of entities for a given suffix

  modalities = bids.schema.return_modality_groups(schema);

  for iModality = 1:numel(modalities)

    datatypes = schema.modalities.(modalities{iModality}).datatypes;

    for iDatatype = 1:numel(datatypes)

      idx = bids.schema.find_suffix_group(datatypes{iDatatype}, suffix, schema, quiet);
      if ~isempty(idx)
        this_datatype = datatypes{iDatatype};
        this_suffix_group = schema.datatypes.(this_datatype)(idx);
        break
      end

    end

    if ~isempty(idx)
      is_required = check_if_required(this_suffix_group);
      entities = bids.schema.return_modality_entities(this_suffix_group, schema);
      break
    end

  end

end

function is_required = check_if_required(this_suffix_group)

  entities = fieldnames(this_suffix_group.entities);
  nb_entities = numel(entities);

  is_required = false(1, nb_entities);

  for i = 1:nb_entities
    if strcmpi(this_suffix_group.entities.(entities{i}), 'required')
      is_required(i) = true;
    end
  end

end
