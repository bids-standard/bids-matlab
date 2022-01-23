classdef File
  %
  % Class to deal with BIDS files and to help to create BIDS valid names
  %
  % USAGE::
  %
  %   file = bids.File(input, ...
  %                    'use_schema', false, ...
  %                    'tolerant', true,
  %                    'verbose', false);
  %
  % :param input:
  % :type input: filename or structure
  % :param use_schema:
  % :type use_schema: boolean
  % :param tolerant: turns errors into warning
  % :type tolerant: boolean
  % :param verbose: silences warnings
  % :type verbose: boolean
  %
  %
  % **Initiliaze with a filename**
  %
  % EXAMPLE::
  %
  %   input = fullfile(pwd, 'sub-01_ses-02_T1w.nii');
  %   file = bids.File(input);
  %
  %
  % **Initialize with a structure**
  %
  % EXAMPLE::
  %
  %   input = struct('ext', '.nii', ...
  %                  'suffix', 'T1w', ...
  %                  'entities', struct('sub', '01', ...
  %                                     'ses', '02'));
  %   file = bids.File(input);
  %
  %
  % **Remove prefixes and add a ``desc-preproc`` entity-label pair**
  %
  % EXAMPLE::
  %
  %   input = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  %   file = bids.File(input, 'use_schema', false);
  %   file.prefix = '';
  %   file.entities.desc = 'preproc';
  %   disp(file.filename)
  %
  %
  % **Use the BIDS schema to get entities in the right order**
  %
  % EXAMPLE::
  %
  %   input.suffix = 'bold';
  %   input.ext = '.nii';
  %   input.entities = struct('sub', '01', ...
  %                           'acq', '1pt5', ...
  %                           'run', '02', ...
  %                           'task', 'face recognition');
  %
  %   file = bids.File(name_spec, 'use_schema', true);
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

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

    schema = []     % BIDS schema used

  end

  properties (SetAccess = private)
    changed = false
    tolerant = true
    verbose = false

  end

  methods

    function obj = File(varargin)
      args = inputParser;
      charOrStruct = @(x) isstruct(x) || ischar(x);

      args.addRequired('input', charOrStruct);
      args.addParameter('use_schema', false, @islogical);
      args.addParameter('tolerant', obj.tolerant, @islogical);
      args.addParameter('verbose', obj.verbose, @islogical);

      args.parse(varargin{:});

      obj.tolerant = args.Results.tolerant;
      obj.verbose = args.Results.verbose;

      if isempty(args.Results.input)
        f_struct = struct([]);
      elseif ischar(args.Results.input)
        f_struct = bids.internal.parse_filename(args.Results.input);
      elseif isstruct(args.Results.input)
        f_struct = args.Results.input;
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
        obj.bids_file_error('emptySuffix', 'no suffix specified');
      end

      if isfield(f_struct, 'entities')
        obj.entities = f_struct.entities;
      end

      if args.Results.use_schema
        obj = obj.use_schema();
      end

      obj = obj.update();
    end

    %% Getters
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

    %% Setters
    function obj = set.prefix(obj, prefix)
      if ~isempty(prefix)
        obj.bids_file_error('prefixDefined', 'BIDS do not allow prefixes');
      end

      obj.validate_prefix(prefix);
      obj.prefix = prefix;
      obj.changed = true; %#ok<*MCSUP>
    end

    function obj = set.extension(obj, extension)
      if isempty(extension)
        obj.bids_file_error('emptyExtension', 'no extension specified');
      end

      obj.validate_extension(extension);
      obj.extension = extension;
      obj.changed = true;
    end

    function obj = set.suffix(obj, suffix)
      if isempty(suffix)
        obj.bids_file_error('emptySuffix', 'no suffix specified');
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
        obj.bids_file_error('noEntity', 'No entity-label pairs');
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

    %% other methods
    function obj = update(obj)
      %
      % excuted automatically before getting a value
      %

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
        obj.bids_file_error('emptySuffix');
      else
        fname = [fname '_' obj.suffix];
      end

      if ~isempty(fname)
        fname = fname(2:end);
      end
      fname = [obj.prefix fname];

      obj.filename = [fname obj.extension];

      if isempty(obj.extension)
        obj.bids_file_error('emptyExtension');
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
      %
      % USAGE::
      %
      %   file = file.reorder_entities([entity_order]);
      %
      % If the no entity order is provided, it will try to rely on the schema to
      % find an appropriate order
      %
      % EXAMPLE::
      %
      %   % filename with ses entity in the wrong position
      %   filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
      %   file = bids.File(filename, 'use_schema', false);
      %   file = file.reorder_entities({'sub', 'ses'});
      %
      %   % use the schema to do the reordering
      %   filename = 'wuasub-01_task-faceRecognition_ses-test_run-02_bold.nii';
      %   file = bids.File(filename, 'use_schema', false);
      %   file = file.use_schema();
      %   file = file.reorder_entities();
      %

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
      obj.validate_entities();
      obj = obj.reorder_entities(obj.entity_order);

    end

    function validate_entities(obj)
      %
      % use entity_order got from schema as a proxy for allowed entity keys
      %
      % USAGE::
      %
      %    file.validate_entities();
      %

      % TODO check that entities are in the right order

      if isempty(obj.schema)
        return
      end

      present_entities = fieldnames(obj.entities);
      forbidden_entity = ~ismember(present_entities, obj.entity_order);
      if any(forbidden_entity)
        msg = sprintf(['Entitiy ''%s'' not allowed by BIDS schema.', ...
                       '\nAllowed entities are:\n - %s'], ...
                      present_entities{forbidden_entity}, ...
                      strjoin(obj.entity_order, '\n - '));
        obj.bids_file_error('forbiddenEntity', msg);
      end

    end

    function [obj, required] = get_required_entities(obj)
      %
      % USAGE::
      %
      %   [file, required_entities] = file.get_required_entities()
      %

      if isempty(obj.schema)
        obj.bids_file_error('schemaMissing');
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
        obj.bids_file_error('schemaMissing');
      end

      modality = obj.schema.return_datatypes_for_suffix(obj.suffix);

      if numel(modality) > 1
        msg = sprintf(['The suffix %s exist for several modalities: %s.', ...
                       '\nSpecify which one in name_spec.modality'], ...
                      obj.suffix, ...
                      strjoin(modality, ', '));
        obj.bids_file_error('manyModalityForsuffix', msg);

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
        obj.bids_file_error('schemaMissing');
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
        obj.bids_file_error('requiredEntity', msg);
      end

    end

    %% Things that might go private

    function bids_file_error(obj, id, msg)

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

      bids.internal.error_handling(mfilename(), id, msg, obj.tolerant, obj.verbose);

    end

    function validate_string(obj, str, type, pattern)

      if ~ischar(str)
        obj.bids_file_error(['Invalid' type], 'not chararray');
      end

      if size(str, 1) > 1
        msg = sprintf('%s contains several lines', str);
        obj.bids_file_error(['Invalid' type], msg);
      end

      if ~isempty(str)
        res = regexp(str, pattern, 'once');
        if isempty(res)
          msg = sprintf('%s do not satisfy pattern %s', str, pattern);
          obj.bids_file_error(['Invalid' type], msg);
        end
      end

    end

    function validate_extension(obj, extension)
      obj.validate_string(extension, 'Extension', '^\.[.A-Za-z0-9]+$');
    end

    function validate_word(obj, extension, type)
      obj.validate_string(extension, type, '^[A-Za-z0-9]+$');
    end

    function validate_prefix(obj, prefix)
      obj.validate_string(prefix, 'Prefix', '^[-_A-Za-z0-9]+$');
      res = regexp(prefix, 'sub-', 'once');
      if ~isempty(res)
        msg = sprintf('%s contains ''sub-''', prefix);
        obj.bids_file_error('InvalidPrefix', msg);
      end
    end

  end

end
