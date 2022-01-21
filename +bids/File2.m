classdef File2

  properties
    prefix = ''     % bids prefix
    extension = ''  % file extension
    suffix = ''     % file suffix
    entities = struct([])   % list of entities
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
    tolerant = true
    verbose = false

  end

  methods

    function obj = File2(varargin)
      args = inputParser;
      charOrStruct = @(x) isstruct(x) || ischar(x);

      args.addRequired('input_file', charOrStruct);
      args.addParameter('use_schema', false, @islogical);
      args.addParameter('tolerant', obj.tolerant, @islogical);
      args.addParameter('verbose', obj.verbose, @islogical);

      args.parse(varargin{:});

      obj.tolerant = args.Results.tolerant;
      obj.verbose = args.Results.verbose;

      if isempty(args.Results.input_file)
        f_struct = struct([]);
      elseif ischar(args.Results.input_file)
          f_struct = bids.internal.parse_filename(args.Results.input_file);
      elseif isstruct(args.Results.input_file)
          f_struct = args.Results.input_file;
      end

      obj.verbose = args.Results.verbose;
      obj.tolerant = args.Results.tolerant;

      if isfield(f_struct, 'prefix')
        obj.prefix = f_struct.prefix;
      end

      if isfield(f_struct, 'ext')
        obj.extension = f_struct.ext;
      end

      if isfield(f_struct, 'suffix')
        obj.suffix = f_struct.suffix;
      else
        module = 'File2';
        id = 'emptySuffix';
        msg = 'no suffix specified';
        bids.internal.error_handling(module, id, msg, obj.tolerant, obj.verbose);
      end

      if isfield(f_struct, 'entities')
        obj.entities = f_struct.entities;
      end

      if args.Results.use_schema
        obj = obj.use_schema();
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
      if ~isempty(prefix)
        module = 'bids:File2';
        id = 'prefixDefined';
        msg = 'BIDS do not allow prefixes';
        bids.internal.error_handling(module, id, msg, obj.tolerant, obj.verbose);
      end

      obj.validate_prefix(prefix);
      obj.prefix = prefix;
      obj.changed = true; %#ok<*MCSUP>


    end

    function obj = set.extension(obj, extension)
      if isempty(extension)
        module = 'bids:File2';
        id = 'emptyExtension';
        msg = 'no extension specified';
        bids.internal.error_handling(module, id, msg, obj.tolerant, obj.verbose);
      end

      obj.validate_extension(extension);
      obj.extension = extension;
      obj.changed = true;
    end

    function obj = set.suffix(obj, suffix)
      if isempty(suffix)
        module = 'bids:File2';
        id = 'emptySuffix';
        msg = 'no suffix specified';
        bids.internal.error_handling(module, id, msg, obj.tolerant, obj.verbose);
      end

      obj.validate_word(suffix, 'Suffix');
      obj.suffix = suffix;
      obj.changed = true;
    end

    function obj = set.entities(obj, entities)

      if isempty(entities)
        obj.entities = struct([]);
        obj.changed = true;
        return
      end

      fn = fieldnames(entities);
      contain_value = false;
      for ifn = 1:size(fn, 1)
        key = fn{ifn};
        obj.validate_word(key, 'Entity label');
        val = entities.(key);
        if isempty(val)
          continue
        end
        contain_value = true;
        obj.validate_word(val, 'Entity value');
      end

      if ~contain_value
        module = 'bids:File2';
        id = 'noEntity';
        msg = 'No entity-label pairs';
        bids.internal.error_handling(module, id, msg, obj.tolerant, obj.verbose);
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

      obj.entities(1).(label) = value;
      obj.changed = true;
    end

    function obj = update(obj)

      fname = '';
      path = '';

      fn = fieldnames(obj.entities);

      for i = 1:size(fn, 1)
        key = fn{i};
        val = obj.entities.(key);
        if isempty(val)
          continue
        end
        fname = [fname '_' key '-' val]; %#ok<AGROW>

        if strcmp(key, 'sub')
          path = fullfile(path, [key '-' val]);
        end

        if strcmp(key, 'ses')
          path = fullfile(path, [key '-' val]);
        end
      end

      obj.check_required_entities();

      if isempty(obj.suffix)
        obj.bidsFile_error('emptySuffix');
      else
        fname = [fname '_' obj.suffix];
      end

      if ~isempty(fname)
        fname = fname(2:end);
      end
      fname = [obj.prefix fname];

      obj.filename = [fname obj.extension];

      if isempty(obj.extension)
        obj.bidsFile_error('emptyExtension');
      else
        obj.filename = [fname obj.extension];
      end

      obj.json_filename = [fname '.json'];

      if ~isempty(obj.modality)
        path = fullfile(path, obj.modality);
      end

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

    %% Things that might go private

    function bidsFile_error(obj, id, msg)

      if nargin < 2
        msg = '';
      end

      switch id
        case 'noEntity'
          msg = 'No entity-label pairs.';

        case 'schemaMissing'
          msg = 'no schema specified: run file.use_schema()';

        case 'emptySuffix'
          msg = 'no suffix specified';

        case 'emptyExtension'
          msg = 'no extension specified';

      end

      bids.internal.error_handling(mfilename, id, msg, obj.tolerant, obj.verbose);
    end

  end

  methods (Static)

    function validate_string(str, type, pattern)
      if ~ischar(str)
        module = 'bids:File2';
        id = ['Invalid' type];
        msg = 'not chararray';
        bids.internal.error_handling(module, id, msg, false, true);
      end

      if size(str, 1) > 1
        module = 'bids:File2';
        id = ['Invalid' type];
        msg = sprintf('%s contains several lines', str);
        bids.internal.error_handling(module, id, msg, false, true);
      end

      if ~isempty(str)
        res = regexp(str, pattern, 'once');
        if isempty(res)
          module = 'bids:File2';
          id = ['Invalid' type];
          msg = sprintf('%s do not satisfy pattern %s', str, pattern);
          bids.internal.error_handling(module, id, msg, false, true);
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
      res = regexp(prefix, 'sub-', 'once');
      if ~isempty(res)
        module = 'bids:File2';
        id = 'InvalidPrefix';
        msg = sprintf('%s contains ''sub-''', prefix);
        bids.internal.error_handling(module, id, msg, false, true);
      end
    end

  end

end
