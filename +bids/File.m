classdef File
  %
  % Class to deal with BIDS files
  %
  % USAGE::
  %
  % file = bids.File(input_file, use_schema, name_spec, tolerant, verbose)
  %
  % input_file
  % use_schema
  % name_spec
  % tolerant
  % verbose
  %
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
    default_name_spec = struct([])
    default_tolerant = true
    default_verbose = false
    default_use_schema = false
  end

  methods

    function obj = File(varargin)
      %
      % USAGE::
      %
      % file = bids.File(input_file, use_schema, name_spec, tolerant, verbose)
      %
      % input_file
      % use_schema
      % name_spec
      % tolerant
      % verbose
      %

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

        end

      end

      if p.Results.use_schema
        obj = obj.use_schema();
      end

      if ~isempty(p.Results.name_spec)
        obj = obj.set_name_spec(p.Results.name_spec);
      end

      obj = obj.create_filename();
      obj = create_rel_path(obj);
      obj.entity_order = fieldnames(obj.entities);

    end

    function obj = set_name_spec(obj, name_spec)

      fields = {'prefix', 'entities', 'suffix', 'ext', 'modality'};

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

      obj.schema = bids.Schema();

      obj = obj.get_required_entity_from_schema();
      obj = obj.reorder_entities();
      obj = obj.create_rel_path();

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

      if isempty(obj.modality)
        obj = get_modality_from_schema(obj);
      end
      obj.relative_pth = fullfile(obj.relative_pth, obj.modality);

    end

    function [obj, output] = create_filename(obj, name_spec)

      if nargin > 1 && ~isempty(name_spec)
        obj = obj.set_name_spec(name_spec);
      end

      output = [obj.prefix, obj.concatenate_entities(), '_', obj.suffix, obj.ext];

      obj.filename = output;

    end

    function obj = reorder_entities(obj, entity_order)
      %
      % reorder entities by one of the following ways
      %   - as defined in obj.entity_order
      %   - order defined by entity_order
      %   - schema based: obj.use_schema

      order = obj.entity_order;

      if nargin > 1 && ~isempty(entity_order)

        order = entity_order;

      elseif ~isempty(obj.schema)

        obj = get_entity_order_from_schema(obj);
        order = obj.entity_order;

      end

      if size(order, 2) > 1
        order = order';
      end

      entity_names = fieldnames(obj.entities);

      idx = ismember(entity_names, order);
      obj.entity_order = cat(1, order, entity_names(~idx));

      if size(obj.entity_order, 2) > 1
        obj.entity_order = obj.entity_order';
      end

      tmp = struct();
      for i = 1:numel(obj.entity_order)
        this_entity = obj.entity_order{i};
        if isfield(obj.entities, this_entity)
          tmp.(this_entity) = obj.entities.(this_entity);
        end
      end
      obj.entities = tmp;

    end

    function [obj, required] = get_required_entity_from_schema(obj)

      if isempty(obj.schema)
        error_missing_schema(obj);
        return
      end

      obj = obj.get_modality_from_schema();

      if isempty(obj.modality) || iscell(obj.modality)
        return
      end

      [~, required] = obj.schema.return_entities_for_suffix_modality(obj.suffix, ...
                                                                     obj.modality);

      obj.required_entities = required;

    end

    function [obj, entity_order] = get_entity_order_from_schema(obj)

      if isempty(obj.schema)
        error_missing_schema(obj);
        return
      end

      obj = obj.get_modality_from_schema();

      if isempty(obj.modality) || iscell(obj.modality)
        return
      end

      schema_entities = obj.schema.return_entities_for_suffix_modality(obj.suffix, ...
                                                                       obj.modality);
      for i = 1:numel(schema_entities)
        obj.entity_order{i, 1} = schema_entities{i};
      end

      entity_order = obj.entity_order;

    end

    function [obj, modality] = get_modality_from_schema(obj)

      if isempty(obj.schema)
        error_missing_schema(obj);
        return
      end

      obj.modality = obj.schema.return_datatypes_for_suffix(obj.suffix);

      if numel(obj.modality) > 1
        msg = sprintf(['The suffix %s exist for several modalities: %s.', ...
                       '\nSpecify which one in name_spec.modality'], ...
                      obj.suffix, ...
                      strjoin(obj.modality, ', '));
        bids.internal.error_handling(mfilename, ...
                                     'manyModalityForsuffix', ...
                                     msg, ...
                                     obj.tolerant, ...
                                     obj.verbose);

      else
        % convert to char
        obj.modality = obj.modality{1};
      end

      modality = obj.modality;

    end

    function output = concatenate_entities(obj)

      output = '';

      entity_names = fieldnames(obj.entities);

      if isempty(entity_names)
        bids.internal.error_handling(mfilename, ...
                                     'noEntity', ...
                                     'No entity-label pairs.', ...
                                     obj.tolerant, ...
                                     obj.verbose);
        return
      end

      obj.check_required_entities();

      for iEntity = 1:numel(entity_names)

        this_entity = entity_names{iEntity};

        if isfield(obj.entities, this_entity) && ~isempty(obj.entities.(this_entity))
          thisLabel = bids.internal.camel_case(obj.entities.(this_entity));
          output = [output '_' this_entity '-' thisLabel]; %#ok<AGROW>
        end

      end

      % remove lead '_'
      output(1) = [];

    end

    function check_required_entities(obj)

      if isempty(obj.required_entities)
        return
      end
      missing_required_entity = ~ismember(obj.required_entities, fieldnames(obj.entities));

      if any(missing_required_entity)
        msg = sprintf('Entities ''%s'' cannot not be empty for the suffix ''%s''', ...
                      strjoin(obj.required_entities(missing_required_entity), ', '), ...
                      obj.suffix);
        bids.internal.error_handling(mfilename, 'requiredEntity', msg, obj.tolerant, obj.verbose);
      end

    end

    function error_missing_schema(obj)
      bids.internal.error_handling(mfilename, ...
                                   'schemaMissing', ...
                                   'no schema specified: run file.use_schema()', ...
                                   obj.tolerant, ...
                                   obj.verbose);
    end

  end
end
