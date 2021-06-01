function [filename, pth, json] = create_filename(p, file)
  %
  % Creates a BIDS compatible filename and can be used to create new names to rename files
  %
  % USAGE::
  %
  %   [filename, pth, json] = bids.create_filename(p)
  %
  % :param p:  specification of the filename to create, very similar to the output of
  %                   ``bids.internal.parse_filename``
  % :type  p:  structure
  %
  % Content of ``p``:
  %
  %   - ``p.suffix``        - required
  %   - ``p.ext``           - extension (default: ``p.ext = ''``)
  %   - ``p.entities``      - structure listing the entity-label pairs to compose the filename
  %   - ``p.prefix``        - prefex to prepend (default: ``p.prefix = ''``)
  %   - ``p.use_schema``    - bollean to check required entities for a given suffix,
  %                           and reorder entities according to the BIDS schema.
  %   - ``p.entity_order``  - user specified order in which to arranges the entities
  %                           in the filename. Overrides ``p.use_schema``.
  %   - ``p.modality``      - string to define the modality of the file
  %                           (example: ``p.modality = 'meg``). If ``p.use_schema == true``
  %                           the function will try to guess it from the
  %                           bids schema.
  %
  % If no entity order is specified and the filename creation is not based on the BIDS
  % schema, then the filename will be created by concatenating the entity-label pairs
  % found in the content of ``p.entities``.
  %
  % USAGE::
  %
  % [filename, pth, json] = bids.create_filename(p, file)
  %
  % :param file: file whose name has to be modified by the content of ``p``.
  % :type file:  string
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  % ----------------------------------------------------------------
  % this needs some serious refactoring !!!!
  default.use_schema = true;
  default.entity_order = {};

  p = bids.internal.match_structure_fields(p, default);

  if isempty(p.use_schema)
    p.use_schema = default.use_schema;
  end

  if nargin > 1
    p = rename_file(p, file);
  end

  if ~isfield(p, 'suffix')
    error('We need at least a suffix to create a filename.');
  end

  default.ext = '';
  default.prefix = '';
  p = bids.internal.match_structure_fields(p, default);

  if ~isfield(p, 'modality')
    p.modality = {};
  end
  if isempty(p.modality) && p.use_schema
    p = get_modality_from_schema(p);
  end
  if ~iscell(p.modality)
    p.modality = {p.modality};
  end
  % ----------------------------------------------------------------

  entities = fieldnames(p.entities);

  [p, entities, required_entities] = reorder_entities(p, entities);

  filename = '';
  for iEntity = 1:numel(entities)

    this_entity = entities{iEntity};

    if ~isempty(required_entities) && ...
            ismember(this_entity, required_entities) && ...
            ~isfield(p.entities, this_entity)

      tolerant = false;
      msg = sprintf('The entity %s cannot not be empty for the suffix %s', ...
                    this_entity, ...
                    p.suffix);
      bids.internal.error_handling(mfilename, 'requiredEntity', msg, tolerant);
    end

    if isfield(p.entities, this_entity) && ~isempty(p.entities.(this_entity))
      thisLabel = bids.internal.camel_case(p.entities.(this_entity));
      filename = [filename '_' this_entity '-' thisLabel]; %#ok<AGROW>
    end

  end

  % remove lead '_'
  filename(1) = [];

  filename = [p.prefix, filename '_', p.suffix, p.ext];

  pth = bids.create_path(filename);
  modality_folder = bids.internal.file_utils(pth, 'filename');
  if ~isempty(p.modality) && ~strcmp(modality_folder, p.modality)
    pth = fullfile(pth, p.modality);
  end
  pth = char(pth);

  json = bids.derivatives_json(filename);

end

function parsed_file = rename_file(p, file)

  parsed_file = bids.internal.parse_filename(file);

  parsed_file.entity_order = p.entity_order;
  parsed_file.use_schema = p.use_schema;

  if isfield(p, 'prefix')
    parsed_file.prefix = p.prefix;
  end

  if isfield(p, 'suffix')
    parsed_file.suffix = p.suffix;
  end

  if isfield(p, 'ext')
    parsed_file.ext = p.ext;
  end

  if isfield(p, 'modality')
    parsed_file.modality = p.modality;
  end

  if isfield(p, 'entities')
      entities_to_change = fieldnames(p.entities);

      for iEntity = 1:numel(entities_to_change)
        parsed_file.entities.(entities_to_change{iEntity}) = p.entities.(entities_to_change{iEntity});
      end
  end

end

function [p, entities, required_entities] = reorder_entities(p, entities)
  %
  % reorder entities by one of the following ways
  %   - user defined: p.entity_order
  %   - schema based: p.use_schema
  %   - order defined by entities order in p.entities
  %

  required_entities = {};

  if ~isempty(p.entity_order)

    if size(p.entity_order, 2) > 1
      p.entity_order = p.entity_order';
    end

  elseif p.use_schema

    [p, required_entities] = get_entity_order_from_schema(p);

  end

  idx = ismember(entities, p.entity_order);
  entities = cat(1, p.entity_order, entities(~idx));

end

function [p] = get_modality_from_schema(p)

  schema = bids.schema();
  schema = schema.load(p.use_schema);

  p.modality = schema.return_datatypes_for_suffix(p.suffix);

  if numel(p.modality) > 1
    tolerant = false;
    msg = sprintf(['The suffix %s exist for several modalities: %s.', ...
                   '\nSpecify which one in p.modality'], ...
                  p.suffix, ...
                  strjoin(p.modality, ', '));
    bids.internal.error_handling(mfilename, 'manyModalityForsuffix', msg, tolerant);
  end

end

function [p, required_entities] = get_entity_order_from_schema(p)

  schema = bids.schema();
  schema = schema.load(p.use_schema);

  [schema_entities, required_entities] = schema.return_entities_for_suffix_modality(p.suffix, ...
                                                                                    p.modality{1});

  for i = 1:numel(schema_entities)
    p.entity_order{i, 1} = schema_entities{i};
  end

end
