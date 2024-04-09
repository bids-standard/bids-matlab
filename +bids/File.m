classdef File
  %
  % Class to deal with BIDS filenames
  %
  % USAGE::
  %
  %   bf = bids.File(input, ...
  %                    'use_schema', false, ...
  %                    'tolerant', true,
  %                    'verbose', false);
  %
  % :param input:      path to the file or a structure with the file information
  % :type  input:      filename or structure
  %
  % :param use_schema: will apply the BIDS schema when parsing or creating filenames
  % :type  use_schema: logical
  %
  % :param tolerant:   turns errors into warning when set to ``true``
  % :type  tolerant:   logical
  %
  % :param verbose:    silences warnings
  % :type  verbose:    logical
  %
  %
  % Examples
  % --------
  %
  % Initialize with a filename.
  %
  % .. code-block:: matlab
  %
  %   input = fullfile(pwd, 'sub-01_ses-02_T1w.nii');
  %   bf = bids.File(input);
  %
  % Initialize with a structure
  %
  % .. code-block:: matlab
  %
  %   input = struct('ext', '.nii', ...
  %                  'suffix', 'T1w', ...
  %                  'entities', struct('sub', '01', ...
  %                                     'ses', '02'));
  %   bf = bids.File(input);
  %
  % Remove prefixes and add a ``desc-preproc`` entity-label pair.
  %
  % .. code-block:: matlab
  %
  %   input = 'wuasub-01_ses-test_task-faceRecognition_run-02_bold.nii';
  %   bf = bids.File(input, 'use_schema', false);
  %   bf.prefix = '';
  %   bf.entities.desc = 'preproc';
  %   disp(file.filename)
  %
  % Use the BIDS schema to get entities in the right order.
  %
  % .. code-block:: matlab
  %
  %   input.suffix = 'bold';
  %   input.ext = '.nii';
  %   input.entities = struct('sub', '01', ...
  %                           'acq', '1pt5', ...
  %                           'run', '02', ...
  %                           'task', 'face recognition');
  %
  %   bf = bids.File(name_spec, 'use_schema', true);
  %
  % Load metadata (supporting inheritance).
  %
  % .. code-block:: matlab
  %
  %   bf = bids.File('tests/data/synthetic/sub-01/anat/sub-01_T1w.nii.gz');
  %
  % Access metadata
  %
  % .. code-block:: matlab
  %
  %   bf.metadata()
  %
  %     struct with fields:
  %       Manufacturer: 'Siemens'
  %       FlipAngle: 10
  %
  % Modify metadata
  %
  % .. code-block:: matlab
  %
  %   % Adding new value
  %
  %   bf = bf.metadata_add('NewField', 'new value');
  %   bf.metadata()
  %
  %     struct with fields:
  %       manufacturer: 'siemens'
  %       flipangle: 10
  %       NewField: 'new value'
  %
  %   % Appending to existing value
  %
  %   bf = bf.metadata_append('NewField', 'new value 1');
  %   bf.metadata()
  %
  %     struct with fields:
  %       manufacturer: 'siemens'
  %       flipangle: 10
  %       NewField: {'new value'; 'new value 1'}
  %
  %   % Removing value
  %
  %   bf = bf.metadata_remove('NewField');
  %   bf.metadata()
  %
  %     struct with fields:
  %       manufacturer: 'siemens'
  %       flipangle: 10
  %
  % Modify several fields of metadata
  %
  % .. code-block:: matlab
  %
  %   bf = bf.metadata_update('Description', 'source file', ...
  %                         'NewField', 'new value', ...
  %                         'manufacturer', []);
  %   bf.metadata()
  %
  %     struct with fields:
  %       flipangle: 10
  %       description: 'source file'
  %       NewField: 'new value'
  %
  % Export metadata as json:
  %
  % .. code-block:: matlab
  %
  %   bf.metadata_write()
  %
  %

  % (C) Copyright 2021 BIDS-MATLAB developers

  properties

    prefix = ''     % bids prefix

    extension = ''  % file extension

    suffix = ''     % file suffix

    entities = struct([])   % list of entities

    modality = ''   % name of file modality

    path = ''    % absolute path

    bids_path = ''  % path within dataset

    filename = ''   % bidsified name

    json_filename = ''  % bidsified name for json file

    metadata_files = {} % list of metadata files related

    metadata  = [] % list of metadata for this file

    entity_required = {}  % Required entities

    entity_order = {}   % Expected order of entities

    schema = []     % BIDS schema used

    tolerant = true

    verbose = false

    padding = 2

  end

  properties (SetAccess = private)
    changed = false
  end

  methods

    function obj = File(varargin)
      args = inputParser;
      charOrStruct = @(x) isstruct(x) || ischar(x);

      args.addRequired('input', charOrStruct);
      args.addParameter('use_schema', false, @islogical);
      args.addParameter('tolerant', obj.tolerant, @islogical);
      args.addParameter('verbose', obj.verbose, @islogical);
      args.addParameter('padding', obj.padding, @isnumeric);

      args.parse(varargin{:});

      obj.tolerant = args.Results.tolerant;
      obj.verbose = args.Results.verbose;
      obj.padding = args.Results.padding;

      if args.Results.use_schema
        obj.schema = bids.Schema();
      end

      if isempty(args.Results.input)
        f_struct = struct([]);
      elseif ischar(args.Results.input)
        if ~isempty(fileparts(args.Results.input))
          obj.path = args.Results.input;
        end
        f_struct = bids.internal.parse_filename(args.Results.input);

        obj.modality = '';
        if isfield(f_struct, 'entities')
          obj.modality = obj.get_modality(f_struct.entities);
        end
      elseif isstruct(args.Results.input)
        f_struct = args.Results.input;
      end

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
        f_struct.entities = obj.pad_indices(f_struct.entities);
        obj.entities = f_struct.entities;
      end

      if isfield(f_struct, 'modality')
        obj.modality = f_struct.modality;
      end

      if isfield(f_struct, 'entities')
        obj.entities = f_struct.entities;
      end

      if args.Results.use_schema
        obj = obj.use_schema();
      end

      obj = obj.set_metadata();

      obj = obj.update();
    end

    function structure = pad_indices(obj, structure)
      fields = fieldnames(structure);
      pattern = ['%0', num2str(obj.padding), '.0f'];
      if obj.padding <= 0
        pattern = '%0.0f';
      end
      for i = 1:numel(fields)
        if isnumeric(structure.(fields{i}))
          structure.(fields{i}) = sprintf(pattern, ...
                                          structure.(fields{i}));
        end
      end

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
        val = bids.internal.camel_case(entities.(key));
        if isempty(val)
          continue
        end
        contain_value = true;
        obj.validate_word(val, 'Entity value');
      end

      if ~strcmp(obj.filename, 'participants.tsv') && ~contain_value
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

    function obj = set_metadata(obj)
      if isempty(obj.metadata_files)
        pattern = '^.*%s\\.json$';
        obj.metadata_files = bids.internal.get_meta_list(obj.path, pattern);
      end
      obj.metadata =  bids.internal.get_metadata(obj.metadata_files);
    end

    function obj = set_entity(obj, label, value)
      obj.validate_word(label, 'Entity label');
      obj.validate_word(value, 'Entity value');

      obj.entities(1).(label) = bids.internal.camel_case(value);
      obj.changed = true;
    end

    function obj = set_metadata_files(obj, pattern)
      if nargin < 2
        pattern = '^.*%s\\.json$';
      end
      obj.metadata_files = bids.internal.get_meta_list(obj.path, pattern);
    end

    %% other methods
    function obj = update(obj)
      %
      % executed automatically before getting a value
      %

      fname = '';
      path = ''; %#ok<*PROP>

      fn = fieldnames(obj.entities);

      for i = 1:size(fn, 1)
        key = fn{i};
        val = bids.internal.camel_case(obj.entities.(key));
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
      %   file = file.reorder_entities(entity_order);
      %
      % :param entity_order: Optional. The order of the entities.
      % :type entity_order:  cell of char
      %
      % If the no entity order is provided, it will try to rely on the schema to
      % find an appropriate order
      %
      % Example
      % -------
      %
      % .. code-block:: matlab
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

      else
        if ~isempty(obj.schema)
          obj = get_entity_order_from_schema(obj);
          order = obj.entity_order;
        else
          schema = bids.Schema;
          entities = schema.entity_order();
          for i = 1:numel(entities)
            order{i, 1} = schema.return_entity_key(entities{i});
          end
        end
      end

      if size(order, 2) > 1
        order = order';
      end
      entity_names = fieldnames(obj.entities);
      idx = ismember(entity_names, order);

      obj.entity_order = cat(1, order, entity_names(~idx));
      % forget about extra entities when using the schema
      if ~isempty(obj.schema)
        obj.entity_order = order;
        if any(~idx)
          obj.bids_file_error('extraEntityForSuffix', ...
                              sprintf('Unknown entity for suffix "%s": "%s"', ...
                                      obj.suffix, strjoin(entity_names(~idx), ', ')));
        end
      end

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

    function obj = rename(obj, varargin)
      %
      % Renames a file according following some specification
      %
      % USAGE::
      %
      %   file = file.rename('spec', spec, 'dry_run', true, 'verbose', [], 'force', false);
      %
      % :param spec: structure specifying what entities, suffix, extension... to apply
      %              If one of the entities in the ``spec`` contains a `'.'`
      %              it will be replaced by `pt`.
      % :type  spec: structure
      %
      % :param dry_run: If ``true`` no file is actually renamed.
      %                 ``true`` is the default to avoid renaming files by mistake.
      % :type dry_run: logical
      %
      % :param verbose: displays ``input --> output``
      % :type verbose: logical
      %
      % :param force: Overwrites existing file.
      % :type force: logical
      %
      % Example
      % -------
      %
      % .. code-block:: matlab
      %
      %   %% rename an SPM preprocessed file
      %
      %   % expected_name = fullfile(pwd, ...
      %   %                         'sub-01', ...
      %   %                         'sub-01_task-faceRep_space-individual_desc-preproc_bold.nii');
      %
      %   input_filename = 'uasub-01_task-faceRep_bold.nii';
      %
      %   file = bids.File(input_filename, 'use_schema', false);
      %
      %   spec.prefix = ''; % remove prefix
      %   spec.entities.desc = 'preproc'; % add description entity
      %   spec.entity_order = {'sub', 'task', 'desc'};
      %
      %   file = file.rename('spec', spec, 'dry_run', false, 'verbose', true);
      %
      %   %% Get a specific file from a dataset to rename
      %
      %   BIDS = bids.layout(path_to_dataset)
      %
      %   % construct a filter to get only the file we want/
      %   subject = '001';
      %   run = '001';
      %   suffix = 'bold';
      %   task = 'faceRep';
      %   filter = struct('sub', subject, 'task', task, 'run', run, 'suffix', suffix);
      %
      %   file_to_rename = bids.query(BIDS, 'data', filter);
      %
      %   file = bids.File(file_to_rename, 'use_schema', false);
      %
      %   % specification to remove run entity
      %   spec.entities.run = '';
      %
      %   % first run with dry_run = true to make sure we will get the expected output
      %   file = file.rename('spec', spec, 'dry_run', true, 'verbose', true);
      %
      %   % rename the file by setting dry_run to false
      %   file = file.rename('spec', spec, 'dry_run', false, 'verbose', true);
      %

      args = inputParser;
      args.addParameter('dry_run', true, @islogical);
      args.addParameter('force', false, @islogical);
      args.addParameter('verbose', []);
      args.addParameter('spec', struct([]), @isstruct);
      args.parse(varargin{:});

      if ~isempty(args.Results.spec)
        spec = args.Results.spec;
        if isfield(spec, 'prefix')
          obj.prefix = spec.prefix;
        end
        if isfield(spec, 'suffix')
          obj.suffix = spec.suffix;
        end
        if isfield(spec, 'ext')
          obj.extension = spec.ext;
        end
        if isfield(spec, 'entities')
          spec.entities = obj.pad_indices(spec.entities);
          spec.entities = obj.normalize_entities(spec.entities);
          entities = fieldnames(spec.entities); %#ok<*PROPLC>
          for i = 1:numel(entities)
            obj = obj.set_entity(entities{i}, ...
                                 bids.internal.camel_case(spec.entities.(entities{i})));
          end

        end
        if isfield(spec, 'entity_order')
          obj = obj.reorder_entities(spec.entity_order);
        end

        obj = obj.update;
      end

      if ~isempty(args.Results.verbose) && islogical(args.Results.verbose)
        obj.verbose = args.Results.verbose;
      end

      if obj.verbose
        fprintf(1, '%s --> %s\n', bids.internal.format_path(obj.path), ...
                bids.internal.format_path(fullfile(fileparts(obj.path), obj.filename)));
      end

      if ~args.Results.dry_run
        % TODO update obj.path
        output_file = fullfile(fileparts(obj.path), obj.filename);
        if ~exist(output_file, 'file') || args.Results.force
          movefile(obj.path, output_file);
          obj.path = output_file;
        else
          bids.internal.error_handling(mfilename(), 'fileAlreadyExists', ...
                                       sprintf(['file %s already exist. ', ...
                                                'Use ''force'' to overwrite.'], ...
                                               bids.internal.format_path(output_file)), ...
                                       obj.tolerant, ...
                                       obj.verbose);
        end
      end

    end

    function entities = normalize_entities(~, entities, replace)
      % Clean up entities
      %
      % Replaces "." in entity label with "pt".
      %
      %
      % USAGE::
      %
      %   entities = file.normalize_entities(entities);
      %
      REPLACE(1) = struct('in', '.', 'out', 'pt');
      if nargin < 3
        replace = REPLACE;
      end

      entities_names = fieldnames(entities); %#ok<*PROPLC>
      for j = 1:numel(replace)
        for i = 1:numel(entities_names)
          entities.(entities_names{i}) = strrep(entities.(entities_names{i}), ...
                                                REPLACE(j).in, ...
                                                REPLACE(j).out);
        end
      end
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

      if isempty(obj.schema)
        obj.schema = bids.Schema();
      end

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
        msg = sprintf(['Entitiy "%s" not allowed by BIDS schema.', ...
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

      if isempty(obj.modality)
        obj = obj.get_modality_from_schema();
      end
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

      if isempty(obj.modality)
        obj = obj.get_modality_from_schema();
      end
      if isempty(obj.modality) || iscell(obj.modality)
        return
      end

      schema_entities = obj.schema.return_entities_for_suffix_modality(obj.suffix, ...
                                                                       obj.modality);
      % reorder entities because they are not always ordered in the schema
      % TODO make faster
      entity_order = {};
      for i = 1:numel(obj.schema.entity_order)
        this_entity = obj.schema.entity_order{i};
        short_name = obj.schema.content.objects.entities.(this_entity).name;
        if ismember(short_name, schema_entities)
          entity_order{end + 1, 1} = short_name;
        end
      end

      obj.entity_order = entity_order;

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

    % Functions related to metadata manipulation

    function obj = metadata_update(obj, varargin)
      % Update stored metadata with new values passed in varargin,
      % which can be either a structure, or pairs of key-values.
      %
      % See also
      %    bids.util.update_struct
      %
      % USAGE::
      %
      %  f = f.metadata_update(key1, value1, key2, value2);
      %  f = f.metadata_update(struct(key1, value1, ...
      %                        key2, value2));
      obj.metadata = bids.util.update_struct(obj.metadata, varargin{:});
    end

    function obj = metadata_add(obj, field, value)
      % Add a new field (or replace existing) to the metadata structure
      obj.metadata.(field) = value;
    end

    function obj = metadata_append(obj, field, value)
      % Append new value to a metadata.(field)
      % If metadata.(field) is a chararray, it will be first
      % transformed into cellarray.
      if isfield(obj.metadata, field)
        if ischar(obj.metadata.(field))
          value = {obj.metadata.(field); value};
        else
          value = [obj.metadata.(field); value];
        end
      end
      obj.metadata(1).(field) = value;
    end

    function obj = metadata_remove(obj, field)
      % Removes field from metadata
      if isfield(obj.metadata, field)
        obj.metadata = rmfield(obj.metadata, field);
      end
    end

    function out_file = metadata_write(obj, varargin)
      % Export current content of metadata to sidecar json
      % with same name as current file.
      %
      % Metadata fields can be modified with new values passed in varargin,
      % which can be either a structure, or pairs of key-values.
      % These modifications do not affect current File object,
      % and only exported into file.
      % Use bids.File.metadata_update to update current metadata.
      % Returns full path to the exported sidecar json file.
      %
      % See also
      %    bids.util.update_struct
      %
      % USAGE::
      %
      %  f.metadata_write(key1, value1, key2, value2);
      %  f.metadata_write(struct(key1, value1, ...
      %                          key2, value2));
      %

      [path, ~, ~] = fileparts(obj.path);
      out_file = fullfile(path, obj.json_filename);

      der_json = bids.util.update_struct(obj.metadata, varargin{:});
      bids.util.jsonencode(out_file, der_json, 'indent', '  ');
    end

    %% Things that might go private

    function bids_file_error(obj, id, msg)

      if nargin < 2
        msg = '';
      end

      if isempty(obj.schema) && ismember(id, {'prefixDefined'})
        return
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

      id = bids.internal.camel_case(id);

      bids.internal.error_handling(mfilename(), id, msg, obj.tolerant, obj.verbose);

    end

    function validate_string(obj, str, type, pattern)

      if ~ischar(str)
        obj.bids_file_error(['Invalid' type], sprintf('"%s" is not char array', str));
      end

      if size(str, 1) > 1
        msg = sprintf('%s contains several lines', str);
        obj.bids_file_error(['Invalid' type], msg);
      end

      if ~isempty(str)
        res = regexp(str, pattern, 'once');
        if isempty(res)
          msg = sprintf('%s do not satisfy pattern %s', ...
                        str, ...
                        strrep(pattern, '\', '\\'));
          obj.bids_file_error(['Invalid' type], msg);
        end
      end

    end

    function validate_extension(obj, extension)
      obj.validate_string(extension, 'Extension', '^\.[.A-Za-z0-9]+$');
    end

    function validate_word(obj, word, type)
      obj.validate_string(word, type, '^[A-Za-z0-9]+$');
    end

    function validate_prefix(obj, prefix)
      obj.validate_string(prefix, 'Prefix', '^[-_A-Za-z0-9]+$');
      res = regexp(prefix, 'sub-', 'once');
      if ~isempty(res)
        msg = sprintf('%s contains ''sub-''', prefix);
        obj.bids_file_error('InvalidPrefix', msg);
      end
    end

    function modality = get_modality(obj, entities)
      % Retrieves modality out of the path
      %
      % Only works if ses and sub entities match those found in the path
      modality = '';

      if isempty(obj.path) || isempty(fileparts(obj.path))
        return
      end

      if ~isfield(entities, 'sub')
        return
      end

      path = fileparts(obj.path);
      [path, candidate] = fileparts(path);

      has_ses = isfield(entities, 'ses') && ~isempty(entities.ses);
      ses_ok = true;
      if has_ses
        [path, ses] = fileparts(path);
        ses_ok = strcmp(ses, ['ses-' entities.ses]);
      end

      [~, sub] = fileparts(path);
      sub_ok = strcmp(sub, ['sub-' entities.sub]);

      if all([sub_ok, ses_ok])
        modality = candidate;
      end

    end

  end

end
