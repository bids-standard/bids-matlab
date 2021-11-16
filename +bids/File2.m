classdef File2

  properties
    prefix = ''     % bids prefix
    extension = ''  % file extension
    suffix = ''     % file suffix
    entities = []   % list of entities
    modality = ''   % name of file modality

    bids_path = ''  % path within dataset
    filename = ''   % bidsified name
    json_filename = ''  % bidsified name for json file

    entity_required = {}  % Required entities
    entity_order = {}   % Expected order of entities
    schema = []     % Schema used for given modality

  end

  properties (SetAccess = private)
    changed = false
  end

  methods

    function obj = File2(varargin)
      args = inputParser;
      charOrStruct = @(x) isstruct(x) || ischar(x);

      args.addRequired('input_file', charOrStruct);
      args.addParameter('use_schema', false, @islogical);
      args.addParameter('tolerant', true, @islogical);

      args.parse(varargin{:});

      if ischar(args.Results.input_file)
        f_struct = bids.internal.parse_filename(args.Results.input_file);
      else
        f_struct = args.Results.input_file;
      end

      if isfield(f_struct, 'prefix')
        obj.prefix = f_struct.prefix;
      end

      if isfield(f_struct, 'ext')
        obj.extension = f_struct.ext;
      end

      if isfield(f_struct, 'suffix')
        obj.suffix = f_struct.suffix;
      end

      if isfield(f_struct, 'entities')
        obj.entities = f_struct.entities;
      end

      obj = obj.update();
    end

    function value = get.bids_path(obj)
      if obj.changed
        obj = obj.update();
      end
      value = obj.bids_path;
    end

    function value = get.filename(obj)
      if obj.changed
        obj = obj.update();
      end
      value = obj.filename;
    end

    function value = get.json_filename(obj)
      if obj.changed
        obj = obj.update();
      end
      value = obj.json_filename;
    end

    function obj = set.prefix(obj, prefix)
      obj.validate_prefix(prefix);
      obj.prefix = prefix;
      obj.changed = true;
    end

    function obj = set.extension(obj, extension)
      obj.validate_extension(extension);
      obj.extension = extension;
      obj.changed = true;
    end

    function obj = set.suffix(obj, suffix)
      obj.validate_word(suffix, 'Suffix');
      obj.suffix = suffix;
      obj.changed = true;
    end

    function obj = set.entities(obj, entities)

      if isempty(entities)
        obj.entities = [];
        obj.changed = true;
        return
      end

      fn = fieldnames(entities);
      for ifn = 1:size(fn, 1)
        key = fn{ifn};
        obj.validate_word(key, 'Entity label');
        val = entities.(key);
        if isempty(val)
          continue
        end
        obj.validate_word(val, 'Entity value');
      end
      obj.entities = entities;
      obj.changed = true;
    end

    function obj = set.modality(obj, modality)
      obj.validate_string(modality, 'Modality', '^[-\w]+$');
      obj.modality = modality;
      obj.changed = true;
    end

    function obj = set_entity(obj, label, value)
      obj.validate_word(label, 'Entity label');
      obj.validate_word(value, 'Entity value');

      obj.entities.(label) = value;
      obj.changed = true;
    end

    function obj = update(obj)
      filename = obj.prefix;
      path = '';

      fn = fieldnames(obj.entities);
      for i = 1:size(fn, 1)
        key = fn{i};
        val = obj.entities.(key);
        if isempty(val)
          continue
        end
        filename = [filename key '-' val '_'];

        if strcmp(key, 'sub')
          path = fullfile(path, [key '-' val]);
        end

        if strcmp(key, 'ses')
          path = fullfile(path, [key '-' val]);
        end
      end

      if ~isempty(obj.suffix)
        filename = [filename obj.suffix];
      end

      obj.filename = [filename obj.extension];
      obj.json_filename = [filename '.json'];
      obj.bids_path = path;

      obj.changed = false;
    end

    function obj = reorder_entities(obj, entity_order)

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

      % reorder obj.entities
      tmp = struct();
      for i = 1:numel(obj.entity_order)
        this_entity = obj.entity_order{i};
        if isfield(obj.entities, this_entity)
          tmp.(this_entity) = obj.entities.(this_entity);
        end
      end
      obj.entities = tmp;
      obj.update();

    end

    %% schema related methods

    function obj = use_schema(obj)
      %
      % Loads BIDS schema into instance and tries to update properties:
      %
      %   - ``file.modality``
      %   - ``file.required_entity``
      %   - ``file.entity_order``
      %   - ``file.relative_pth``
      %
      % USAGE::
      %
      %   file = file.use_schema();
      %

      obj.schema = bids.Schema();
      obj = obj.get_required_entities();
      obj = obj.get_entity_order_from_schema();
      obj = obj.reorder_entities(obj.entity_order);

    end

    function [obj, required] = get_required_entities(obj)
      %
      % USAGE::
      %
      %   [file, required_entities] = file.get_required_entities()
      %

      if isempty(obj.schema)
        obj.bidsFile_error('schemaMissing');
      end

      obj = obj.get_modality_from_schema();
      if isempty(obj.modality) || iscell(obj.modality)
        return
      end

      [~, required] = obj.schema.return_entities_for_suffix_modality(obj.suffix, ...
                                                                     obj.modality);
      obj.entity_required = required;

    end

    function [obj, modality] = get_modality_from_schema(obj)
      %
      % USAGE::
      %
      %   [file, modality] = file.get_modality_from_schema()
      %

      if isempty(obj.schema)
        obj.bidsFile_error('schemaMissing');
      end

      modality = obj.schema.return_datatypes_for_suffix(obj.suffix);

      if numel(modality) > 1
        msg = sprintf(['The suffix %s exist for several modalities: %s.', ...
                       '\nSpecify which one in name_spec.modality'], ...
                      obj.suffix, ...
                      strjoin(modality, ', '));
        bids.internal.error_handling(mfilename, 'manyModalityForsuffix', msg, obj.tolerant, obj.verbose);

      elseif ~isempty(modality)
        % convert to char
        modality = modality{1};

      end

      obj.modality = modality;

    end

    function [obj, entity_order] = get_entity_order_from_schema(obj)
      %
      % USAGE::
      %
      %   [file, entity_order] = file.get_entity_order_from_schema()
      %

      if isempty(obj.schema)
        obj.bidsFile_error('schemaMissing');
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

    function check_required_entities(obj)
      %
      % USAGE::
      %
      %   file.check_required_entities()
      %

      if isempty(obj.entity_required)
        return
      end
      missing_required_entity = ~ismember(obj.entity_required, fieldnames(obj.entities));

      if any(missing_required_entity)
        msg = sprintf('Entities ''%s'' cannot not be empty for the suffix ''%s''', ...
                      strjoin(obj.entity_required(missing_required_entity), ', '), ...
                      obj.suffix);
        obj.bidsFile_error('requiredEntity', msg);
      end

    end
  end

  methods (Static)

    function validate_string(str, type, pattern)
      if ~ischar(str)
        error('%s is not chararray', type);
      end

      if size(str, 1) > 1
        error('%s: %s contains several lines', type, str);
      end

      if ~isempty(str)
        res = regexp(str, pattern);
        if isempty(res)
          error('%s: %s do not satisfy pattern %s', type, str, pattern);
        end
      end
    end

    function validate_extension(extension)
      bids.File2.validate_string(extension, 'Extension', '^\.[.A-Za-z0-9]+$');
    end

    function validate_word(extension, type)
      bids.File2.validate_string(extension, type, '^[A-Za-z0-9]+$');
    end

    function validate_prefix(prefix)
      bids.File2.validate_string(prefix, 'Prefix', '^[-_A-Za-z0-9]+$');
      res = regexp(prefix, 'sub-');
      if ~isempty(res)
        error('Prefix ''%s'' contains ''sub-''', prefix);
      end
    end

  end
end
