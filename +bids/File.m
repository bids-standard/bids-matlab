classdef File
  %
  % Class to deal with BIDS files
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  properties

    schema

    verbose

    tolerant

    entity_order = {}

    required_entities

    modality = ''

    pth = ''

    relative_pth = ''

    filename

    prefix = ''

    entities = struct()

    suffix = ''

    ext = ''

  end

  properties (SetAccess = private)
    default_filename = ''
    default_name_spec = struct()
    default_tolerant = true
    default_verbose = true
    default_use_schema = false
  end

  methods

    function obj = File(varargin)

      p = inputParser;

      charOrStruct = @(x) isstruct(x) || ischar(x);

      addOptional(p, 'input_file', obj.default_filename, charOrStruct);
      addOptional(p, 'use_schema', obj.default_use_schema, @islogical);
      addOptional(p, 'name_spec', obj.default_name_spec, @isstruct);
      addOptional(p, 'tolerant', obj.default_tolerant, @islogical);
      addOptional(p, 'verbose', obj.default_verbose, @islogical);

      parse(p, varargin{:});

      obj.verbose = p.Results.verbose;
      obj.tolerant = p.Results.tolerant;

      input_file = p.Results.input_file;

      if isempty(input_file)
        return

      else

        if ischar(input_file)

          obj.filename = bids.internal.file_utils(input_file, 'filename');
          obj.pth = bids.internal.file_utils(input_file, 'path');

          obj = obj.parse();

        elseif isstruct(input_file)

          obj = obj.set_name_spec(input_file);
          obj = obj.create_filename();

        end

      end

      obj = create_rel_path(obj);

      if p.Results.use_schema
        obj = use_schema(obj);
      end

    end

    function obj = set_name_spec(obj, name_spec)

      fields = {'prefix', 'entities', 'suffix', 'ext'};

      for i = 1:numel(fields)
        if isfield(name_spec, fields{i})

          if strcmp(fields{i}, 'entities')
            entity_names = fieldnames(name_spec.entities);
            for j = 1:numel(entity_names)
              obj.entities.(entity_names{j}) = name_spec.entities.(entity_names{j});
            end
          else
            obj.(fields{i}) = name_spec.(fields{i});
          end

        end
      end

    end

    function obj = use_schema(obj)

      obj.schema = bids.schema();
      obj.schema = obj.schema.load();

      obj = obj.create_rel_path();
      obj = obj.get_required_entity_from_schema();
      obj = obj.get_entity_order_from_schema();

    end

    function obj = parse(obj, fields)

      % TODO add possibility to parse according to BIDS schema
      % (will require to extract function from append_to_layout)

      if nargin < 2
        fields = {};
      end

      if ~isempty(obj.filename)

        parts = bids.internal.parse_filename(obj.filename, fields, obj.tolerant);

        if ~isempty(parts)
          obj.prefix = parts.prefix;
          obj.entities = parts.entities;
          obj.suffix = parts.suffix;
          obj.ext = parts.ext;
        end

      end
    end

    function obj = create_rel_path(obj)

      obj.relative_pth = '';

      if isfield(obj.entities, 'sub')
        obj.relative_pth = ['sub-' obj.entities.sub];
      end

      if isfield(obj.entities, 'ses')
        obj.relative_pth = fullfile(obj.relative_pth, ['ses-' obj.entities.ses]);
      end

      if ~isempty(obj.schema)
        datatypes = obj.schema.return_datatypes_for_suffix(obj.suffix);
        if numel(datatypes) == 1
          obj.relative_pth = fullfile(obj.relative_pth, datatypes{1});
        end
      end

    end

    function obj = create_filename(obj)

      obj.filename = '';

      entity_names = fieldnames(obj.entities);

      for iEntity = 1:numel(entity_names)

        this_entity = entity_names{iEntity};

        if ~isempty(obj.required_entities) && ...
                ismember(this_entity, obj.required_entities) && ...
                ~isfield(obj.entities, this_entity)

          msg = sprintf('The entity %s cannot not be empty for the suffix %s', ...
                        this_entity, ...
                        obj.suffix);
          bids.internal.error_handling(mfilename, 'requiredEntity', msg, obj.tolerant, obj.verbose);
        end

        if isfield(obj.entities, this_entity) && ~isempty(obj.entities.(this_entity))
          thisLabel = bids.internal.camel_case(obj.entities.(this_entity));
          obj.filename = [obj.filename '_' this_entity '-' thisLabel]; %#ok<AGROW>
        end

      end

      % remove lead '_'
      obj.filename(1) = [];

      obj.filename = [obj.prefix, obj.filename '_', obj.suffix, obj.ext];

    end

    function obj = reorder_entities(obj, entity_order)
      %
      % reorder entities by one of the following ways
      %   - order defined by entity_order
      %   - as defined in obj.entity_order
      %   - schema based: obj.use_schema
      %

      if nargin > 1 && ~isempty(entity_order)

        obj.entity_order = entity_order;

      elseif ~isempty(obj.entity_order)

      elseif obj.use_schema

        obj = get_entity_order_from_schema(obj);

      end

      if size(obj.entity_order, 2) > 1
        obj.entity_order = obj.entity_order';
      end

      entity_names = fieldnames(obj.entities);

      idx = ismember(entity_names, obj.entity_order);
      obj.entities = cat(1, obj.entity_order, entity_names(~idx));

    end

    function [obj, required] = get_required_entity_from_schema(obj)

      obj = obj.get_modality_from_schema();

      [~, required] = obj.schema.return_entities_for_suffix_modality(obj.suffix, ...
                                                                     obj.modality{1});

      obj.required_entities = required;

    end

    function [obj, entity_order] = get_entity_order_from_schema(obj)

      obj = obj.get_modality_from_schema();

      schema_entities = obj.schema.return_entities_for_suffix_modality(obj.suffix, ...
                                                                       obj.modality{1});
      for i = 1:numel(schema_entities)
        obj.entity_order{i, 1} = schema_entities{i};
      end

      entity_order = obj.entity_order;

    end

    function obj = get_modality_from_schema(obj)

      obj.modality = obj.schema.return_datatypes_for_suffix(obj.suffix);

      if numel(obj.modality) > 1
        msg = sprintf(['The suffix %s exist for several modalities: %s.', ...
                       '\nSpecify which one in p.modality'], ...
                      obj.suffix, ...
                      strjoin(obj.modality, ', '));
        bids.internal.error_handling(mfilename, ...
                                     'manyModalityForsuffix', ...
                                     msg, ...
                                     obj.tolerant, ...
                                     obj.verbose);
      end

    end

  end
end
