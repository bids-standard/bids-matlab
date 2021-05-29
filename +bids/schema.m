classdef schema
  %
  % Class to interact with the BIDS schema
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  properties
    content
    quiet = true
    is_bids_schema = false
  end

  %% PUBLIC
  methods

    function obj = load(obj, use_schema)
      %
      % Loads a json schema by recursively looking through a folder structure.
      %
      % The nesting of the output structure reflects a combination of the folder structure and
      % any eventual nesting within each json.
      %
      % USAGE::
      %
      %   schema = bids.schema
      %   schema = schema.load
      %

      % TODO:
      %  - folders that do not contain json files themselves but contain
      %  subfolders that do, are not reflected in the output structure (they are
      %  skipped). This can lead to "name conflicts". See "silenced" unit tests
      %  for more info.

      if nargin < 2
        use_schema = true();
      end

      if ~use_schema
        obj.content = struct([]);
        return
      end

      obj.content = [];

      if ischar(use_schema)
        schema_dir = use_schema;
        obj.is_bids_schema = false;
      else
        schema_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'schema');
        obj.is_bids_schema = true;
      end

      if ~exist(schema_dir, 'dir')
        error('The schema directory %s does not exist.', schema_dir);
      end

      [json_file_list, dirs] = bids.internal.file_utils('FPList', schema_dir, '^.*.json$');

      obj.content = obj.append_json_to_schema(obj.content, json_file_list);

      obj.content = obj.inspect_subdir(obj, obj.content, dirs);

      % add extra field listing all required entities
      if obj.is_bids_schema

        mod_grps = obj.return_modality_groups();

        for i = 1:numel(mod_grps)

          mods = obj.return_modalities([], mod_grps{i});

          for j = 1:numel(mods)

            suffix_grps = obj.content.datatypes.(mods{j});
            % need to use a tmp variable to avoid some errors in continuous
            % integration to avoid some errors with octave
            updated_suffix_grps = struct('suffixes', [], ...
                                         'extensions', [], ...
                                         'entities', [], ...
                                         'required_entities', []);

            for k = 1:numel(suffix_grps)
              this_suffix_group = obj.ci_check(suffix_grps(k));
              required_entities = obj.required_entities_for_suffix_group(this_suffix_group);
              this_suffix_group.required_entities = required_entities;
              updated_suffix_grps(k, 1) = this_suffix_group;
            end

            obj.content.datatypes.(mods{j}) = updated_suffix_grps;

          end
        end
      end

    end

    function modalities = return_modalities(obj, subject, modality_group)
      % if we go schema-less or use another schema than the "official" one
      % we list directories in the subject/session folder
      % as proxy of the modalities that we have to parse
      if ~obj.is_bids_schema || isempty(obj.content)
        modalities = cellstr(bids.internal.file_utils('List', ...
                                                      subject.path, ...
                                                      'dir', ...
                                                      '.*'));
      else
        modalities = obj.content.modalities.(modality_group).datatypes;

      end
    end

    % ----------------------------------------------------------------------- %
    %% MODALITIES
    function groups = return_modality_groups(obj)
      %
      % Returns a dummy variable if we go schema less
      %
      groups = {nan()};
      if ~isempty(obj.content) && isfield(obj.content, 'modalities')
        groups = fieldnames(obj.content.modalities);
      end
    end

    % ----------------------------------------------------------------------- %
    %% SUFFIX GROUP

    function entities = return_entities_for_suffix_group(obj, suffix_group)
      suffix_group = obj.ci_check(suffix_group);

      entity_names = fieldnames(suffix_group.entities);

      for i = 1:size(entity_names, 1)
        entities{1, i} = obj.content.entities.(entity_names{i}).entity; %#ok<*AGROW>
      end

    end

    function required_entities = required_entities_for_suffix_group(obj, this_suffix_group)
      %
      %  Returns a logical vector to track which entities of a suffix group
      %  are required in the bids schema
      %
      this_suffix_group = obj.ci_check(this_suffix_group);

      if isfield(this_suffix_group, 'required_entities')
        required_entities = this_suffix_group.required_entities;
        return
      end

      entities_long_name = fieldnames(this_suffix_group.entities);
      nb_entities = numel(entities_long_name);

      entities = obj.return_entities_for_suffix_group(this_suffix_group);

      is_required = false(1, nb_entities);

      for i = 1:nb_entities
        if strcmpi(this_suffix_group.entities.(entities_long_name{i}), 'required')
          is_required(i) = true;
        end
      end

      required_entities = entities(is_required);

    end

    function idx = find_suffix_group(obj, modality, suffix)
      %
      % For a given sufffix and modality, this returns the "suffix group" this
      % suffix belongs to
      %

      idx = [];

      if isempty(obj.content)
        return
      end

      % the following loop could probably be improved with some cellfun magic
      %   cellfun(@(x, y) any(strcmp(x,y)), {p.type}, suffix_groups)
      for i = 1:size(obj.content.datatypes.(modality), 1)
        this_suffix_group = obj.content.datatypes.(modality)(i);
        this_suffix_group = obj.ci_check(this_suffix_group);
        if any(strcmp(suffix, this_suffix_group.suffixes))
          idx = i;
          break
        end
      end

      if isempty(idx) && ~obj.quiet
        warning('findSuffix:noMatchingSuffix', ...
                'No corresponding suffix in schema for %s for datatype %s', suffix, modality);
      end
    end

    % ----------------------------------------------------------------------- %
    %% SUFFIXES
    function datatypes = return_datatypes_for_suffix(obj, suffix)
      %
      % For a given suffix, returns all the possible datatypes that have this suffix.
      %

      datatypes = {};

      if isempty(obj.content)
        return
      end

      datatypes_list = fieldnames(obj.content.datatypes);

      for i = 1:size(datatypes_list, 1)

        this_datatype = obj.content.datatypes.(datatypes_list{i});
        this_datatype = obj.ci_check(this_datatype);

        suffix_list = cat(1, this_datatype.suffixes);

        if any(ismember(suffix_list, suffix))
          datatypes{end + 1} = datatypes_list{i};
        end

      end
    end

    function [entities, required_entities] = return_entities_for_suffix(obj, suffix)
      %
      % returns the list of entities for a given suffix
      %

      modalities = obj.return_modality_groups;

      for iModality = 1:numel(modalities)

        datatypes = obj.content.modalities.(modalities{iModality}).datatypes;

        for iDatatype = 1:numel(datatypes)
          idx = obj.find_suffix_group(datatypes{iDatatype}, suffix);
          if ~isempty(idx)
            this_datatype = datatypes{iDatatype};
            this_suffix_group = obj.content.datatypes.(this_datatype)(idx);
            break
          end
        end

        if ~isempty(idx)
          required_entities = obj.required_entities_for_suffix_group(this_suffix_group);
          entities = obj.return_entities_for_suffix_group(this_suffix_group);
          break
        end

      end

    end

    % ----------------------------------------------------------------------- %
    %% REGEX GENERATION
    function regex = return_modality_suffixes_regex(obj, modality)
      regex = obj.return_regex(modality, 'suffixes');
    end

    function regex = return_modality_extensions_regex(obj, modality)
      regex = obj.return_regex(modality, 'extensions');
    end

    function modality_regex = return_modality_regex(obj, modality)
      suffixes = obj.return_modality_suffixes_regex(modality);
      extensions = obj.return_modality_extensions_regex(modality);
      modality_regex = ['^%s.*' suffixes extensions '$'];
    end

  end

  % ----------------------------------------------------------------------- %
  %% STATIC
  methods (Static)

    %% Loading related methods
    function structure = append_json_to_schema(structure, json_file_list)
      %
      % Reads a json file and appends its content to the bids schema
      %
      for iFile = 1:size(json_file_list, 1)
        file = deblank(json_file_list(iFile, :));

        field_name = bids.internal.file_utils(file, 'basename');

        structure.(field_name) = bids.util.jsondecode(file);
      end

    end

    function structure = inspect_subdir(obj, structure, subdir_list)
      %
      % Recursively inspects subdirectory for json files and reflects folder
      % hierarchy in the output structure.
      %
      for iDir = 1:size(subdir_list, 1)

        directory = deblank(subdir_list(iDir, :));

        [json_file_list, dirs] = bids.internal.file_utils('FPList', directory, '^.*.json$');

        if ~isempty(json_file_list)
          field_name = bids.internal.file_utils(directory, 'basename');
          structure.(field_name) = struct();
          structure.(field_name) = obj.append_json_to_schema(structure.(field_name), ...
                                                             json_file_list);
        end

        structure = obj.inspect_subdir(obj, structure, dirs);

      end
    end

    %% Other
    function variable_to_check = ci_check(variable_to_check)
      % Mostly to avoid some crash in continuous integration
      if iscell(variable_to_check)
        variable_to_check = variable_to_check{1};
      end
    end

  end

  % ----------------------------------------------------------------------- %
  %% PRIVATE
  methods (Access = private)

    function regex = return_regex(obj, modality, level)
      modality = obj.ci_check(modality);

      regex = '(';
      if strcmp(level, 'suffixes')
        regex = ['_' regex];
      end

      for i = 1:numel(modality(:).(level))
        if ~strcmp(modality.(level){i}, '.json')
          regex = [regex,  modality.(level){i}, '|']; %#ok<AGROW>
        end
      end

      % Replace final "|" by a "){1}"
      regex(end:end + 3) = '){1}';
    end

  end

end
