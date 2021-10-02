classdef File
  %
  % Class to deal with BIDS files and to help to create BIDS valid names
  %
  % USAGE::
  %
  %   file = bids.File(input_file, use_schema, name_spec, tolerant, verbose);
  %
  % :param input_file:
  % :type input_file: filename or structure
  % :param use_schema: default  = ``false``
  % :type use_schema: boolean
  % :param name_spec:
  % :type name_spec: structure
  % :param tolerant: turns errors into warning; default  = ``true``
  % :type tolerant: boolean
  % :param verbose: silences warnings; default  = ``false``
  % :type verbose: boolean
  %
  % **Initiliaze with a filename**
  %
  % EXAMPLE::
  %
  %    input_file = fullfile(pwd, 'sub-01_ses-02_T1w.nii');
  %    file = bids.File(input_file);
  %
  % **Initialize with a structure**
  %
  % EXAMPLE::
  %
  %    input_file = struct('ext', '.nii', ...
  %                        'suffix', 'T1w', ...
  %                        'entities', struct('sub', '01', ...
  %                                           'ses', '02'));
  %    file = bids.File(input_file);
  %
  % **Remove prefixes and add a ``desc-preproc`` entity-label pair**
  %
  % EXAMPLE::
  %
  %   filename = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  %   use_schema = false;
  %
  %   name_spec.prefix = '';
  %   name_spec.entities = struct('desc', 'preproc');
  %
  %   file = bids.File(filename, use_schema, name_spec);
  %
  % **Use the BIDS schema to get entities in the right order**
  %
  % EXAMPLE::
  %
  %   name_spec.suffix = 'bold';
  %   name_spec.ext = '.nii';
  %   name_spec.entities = struct( ...
  %                               'sub', '01', ...
  %                               'acq', '1pt5', ...
  %                               'run', '02', ...
  %                               'task', 'face recognition');
  %   use_schema = true;
  %
  %   file = bids.File(name_spec, use_schema);
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  properties

    filename % filename

    pth = '' % path

    relative_pth = '' % path relative to the root of the BIDS dataset

    prefix = '' %

    entities = struct() % structure of entity name - label pairs

    suffix = '' %

    ext = '' %

    modality = '' % modality inferred from schema if not specified by user

    required_entities % required entities  inferred from schema

    entity_order = {} % entity order inferred from schema

    schema

    verbose

    tolerant

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
      % Constructor
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
      %
      % Updates attributes ``file.prefix``, ``file.entities``, ``file.suffix``,
      % ``file.ext``, ``file.modality``
      %
      % USAGE::
      %
      %   file = file.set_name_spec(name_spec)
      %
      % :param name_spec:
      % :type name_spec: structure
      %
      % EXAMPLE::
      %
      %   file = bids.File();
      %   name_spec = struct('ext', '.nii', ...
      %                      'suffix', 'T1w', ...
      %                      'entities', struct('sub', '01', ...
      %                                         'ses', '02'));
      %   file = file.set_name_spec(name_spec);
      %

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

    function obj = parse(obj, fields)
      %
      % Parse filename and updates attributes
      % ``file.prefix``, ``file.entities``, ``file.suffix``, ``file.ext``, ``file.modality``
      %
      % USAGE::
      %
      %   file = file.parse([fields = {}]);
      %

      % TODO add possibility to parse according to BIDS schema
      % (will require to extract function from append_to_layout)

      if nargin < 2
        fields = {};
      end

      if ~isempty(obj.filename)

        name_spec = bids.internal.parse_filename(obj.filename, fields, obj.tolerant);

        if ~isempty(name_spec)
          obj = obj.set_name_spec(name_spec);
        end

      end
    end

    function obj = create_rel_path(obj)
      %
      % Updates attribute ``file.relative_pth``
      %
      % USAGE::
      %
      %   file = file.create_rel_path();
      %

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
      %
      % Updates attribute ``file.filename``. If ``name_spec`` is passed as argument
      % then the filename will be updated accordingly
      %
      % USAGE::
      %
      %   [file, filename] = file.create_filename([name_spec]);
      %
      % :param name_spec: specifies how to update the
      % :type name_spec: structure
      %

      if nargin > 1 && ~isempty(name_spec)
        obj = obj.set_name_spec(name_spec);
      end

      if isempty(obj.suffix)
        obj.bidsFile_error('emptySuffix');
      end
      if isempty(obj.ext)
        obj.bidsFile_error('emptyExtension');
      end

      output = [obj.prefix, obj.concatenate_entities(), '_', obj.suffix, obj.ext];

      obj.filename = output;

    end

    function obj = reorder_entities(obj, entity_order)
      %
      % Reorder entities by one of the following ways:
      %
      %   - order defined by ``entity_order``
      %   - schema based depending on ``file.use_schema``
      %   - as defined in ``file.entity_order``
      %
      % USAGE::
      %
      %   file = file.reorder_entities(entity_order)
      %

      order = obj.entity_order;

      if nargin > 1 && ~isempty(entity_order)
        order = entity_order;

      elseif ~isempty(obj.schema)
        obj = get_entity_order_from_schema(obj);
        order = obj.entity_order;

      end

      % entities in order are put first:
      % any other entity not included in order come after in the order they were
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

    end

    %% schema related methods

    function obj = use_schema(obj)
      %
      % Loads BIDS schema into instance and tries to update attributes 'modality'
      % ``file.required_entity``, ``file.entity_order``, ``file.relative_pth``
      %
      % USAGE::
      %
      %   file = file.use_schema();
      %

      obj.schema = bids.Schema();

      obj = obj.get_required_entity_from_schema();
      obj = obj.reorder_entities();
      obj = obj.create_rel_path();

    end

    function [obj, required] = get_required_entity_from_schema(obj)
      %
      % USAGE::
      %
      %   [file, required_entities] = file.get_required_entity_from_schema()
      %

      if isempty(obj.schema)
        obj.bidsFile_error('schemaMissing');
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
      %
      % USAGE::
      %
      %   [file, entity_order] = file.get_entity_order_from_schema()
      %

      if isempty(obj.schema)
        obj.bidsFile_error('schemaMissing');
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
      %
      % USAGE::
      %
      %   [file, modality] = file.get_modality_from_schema()
      %

      if isempty(obj.schema)
        obj.bidsFile_error('schemaMissing');
        return
      end

      obj.modality = obj.schema.return_datatypes_for_suffix(obj.suffix);

      if numel(obj.modality) > 1
        obj.bidsFile_error('manyModalityForsuffix');

      else
        % convert to char
        obj.modality = obj.modality{1};
        modality = obj.modality;

      end

    end

    %% Things that might go private

    function output = concatenate_entities(obj)
      %
      % Concatenate entities and checks if there are missing required entities.
      %
      % USAGE::
      %
      %   concatenated_entities = file.concatenate_entities()
      %

      output = '';

      entity_names = fieldnames(obj.entities);

      if isempty(entity_names)
        obj.bidsFile_error('noEntity');
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
      %
      % USAGE::
      %
      %   file.check_required_entities()
      %

      if isempty(obj.required_entities)
        return
      end
      missing_required_entity = ~ismember(obj.required_entities, fieldnames(obj.entities));

      if any(missing_required_entity)
        msg = sprintf('Entities ''%s'' cannot not be empty for the suffix ''%s''', ...
                      strjoin(obj.required_entities(missing_required_entity), ', '), ...
                      obj.suffix);
        obj.bidsFile_error('requiredEntity', msg);
      end

    end

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

        case 'manyModalityForsuffix'
          msg = sprintf(['The suffix %s exist for several modalities: %s.', ...
                         '\nSpecify which one in name_spec.modality'], ...
                        obj.suffix, ...
                        strjoin(obj.modality, ', '));
      end

      bids.internal.error_handling(mfilename, id, msg, obj.tolerant, obj.verbose);
    end

  end
end
