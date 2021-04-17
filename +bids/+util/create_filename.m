function filename = create_filename(p, file)

  if ~isfield(p, 'suffix')
    error('We need at least a suffix to create a filename.');
  end

  if ~isfield(p, 'ext')
    p.ext = '';
  end

  if nargin > 1
    p = rename_file(p, file);
  end

  entities = fieldnames(p.entities);

  [p, entities] = reorder_entities(p, entities);

  filename = '';
  for iEntity = 1:numel(entities)

    thisEntity = entities{iEntity};

    if isfield(p.entities, thisEntity) && ~isempty(p.entities.(thisEntity))
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

function [p, entities, is_required] = reorder_entities(p, entities)

  if isfield(p, 'entity_order')
    if size(p.entity_order, 2) > 1
      p.entity_order = p.entity_order';
    end
    idx = ismember(entities, p.entity_order);

    entities = cat(1, p.entity_order, entities(~idx));
    is_required = false(size(entities));

  elseif isfield(p, 'use_schema')
    [p, is_required] = get_entity_order_from_schema(p);

    idx = ismember(entities, p.entity_order);
    entities = cat(1, p.entity_order, entities(~idx));

  else

    is_required = false(size(entities));

  end

end

function [p, is_required] = get_entity_order_from_schema(p)

  schema = bids.schema.load_schema(p.use_schema);
  [schema_entities, is_required] = bids.schema.return_entities_for_suffix(p.suffix, schema);
  for i = 1:numel(schema_entities)
    p.entity_order{i, 1} = schema_entities{i};
  end

end
