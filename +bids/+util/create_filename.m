function filename = create_filename(p, file)

  if nargin > 1
    p = rename_file(p, file);
  end

  entities = fieldnames(p.entities);
  
  % reorder entities if necessary
  if isfield(p, 'entity_order')
      if size(p.entity_order, 2)>1 
          p.entity_order = p.entity_order';
      end
      idx = ismember(entities, p.entity_order);
      entities = cat(1, p.entity_order, entities(~idx));
  end

  filename = '';
  for iEntity = 1:numel(entities)

    thisEntity = entities{iEntity};

    if ~isempty(p.entities.(thisEntity))
      thisLabel = bids.internal.camel_case(p.entities.(thisEntity));
      filename = [filename '_' thisEntity '-' thisLabel]; %#ok<AGROW>
    end

  end

  % remove lead '_'
  filename(1) = [];

  filename = [filename '_', p.suffix p.ext];

end


function parsed_file = rename_file(p, file)

  parsed_file = bids.internal.parse_filename(file);

  entities_to_change = fieldnames(p.entities);

  for iEntity = 1:numel(entities_to_change)
    parsed_file.entities.(entities_to_change{iEntity}) = p.entities.(entities_to_change{iEntity});
  end

end