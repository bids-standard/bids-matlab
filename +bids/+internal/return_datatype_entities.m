function entities = return_datatype_entities(datatype)

  schema = bids.internal.load_schema();

  entity_names = fieldnames(datatype.entities);

  for i = 1:size(entity_names, 1)
    entities{1, i} = schema.entities.(entity_names{i}).entity; %#ok<*AGROW>
  end

end
