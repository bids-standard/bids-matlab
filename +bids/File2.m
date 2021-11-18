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
      if ~isempty(prefix)
        module = 'bids:File2';
        id = 'prefixDefined';
        msg = 'BIDS do not allow prefixes';
        bids.internal.error_handling(module, id, msg, obj.tolerant, obj.verbose);
      end

      obj.validate_prefix(prefix);
      obj.prefix = prefix;
      obj.changed = true;

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
      if ~isempty(obj.suffix)
        fname = [fname '_' obj.suffix];
      end

      if ~isempty(fname)
        fname = fname(2:end);
      end
      fname = [obj.prefix fname];

      obj.filename = [fname obj.extension];

      obj.json_filename = [fname '.json'];
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
        res = regexp(str, pattern, 'ONCE');
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
      res = regexp(prefix, 'sub-', 'ONCE');
      if ~isempty(res)
        module = 'bids:File2';
        id = 'InvalidPrefix';
        msg = sprintf('%s contains ''sub-''', prefix);
        bids.internal.error_handling(module, id, msg, false, true);
      end
    end

  end
end
