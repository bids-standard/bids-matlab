classdef Schema
  %
  % Class to interact with the BIDS schema
  %
  % USAGE::
  %
  %   schema = bids.Schema(use_schema)
  %
  % use_schema: boolean
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  % TODO use schema to access regular expressions

  properties
    content

    verbose = false %

    is_bids_schema = false %

    load_schema_metadata = false %
  end

  %% PUBLIC
  methods

    function obj = Schema(use_schema)
      %
      % USAGE::
      %
      %   schema = bids.Schema(use_schema)
      %
      % use_schema: boolean
      %

      obj.content = [];
      if nargin < 1
        use_schema = true();
      end
      obj = load(obj, use_schema);
    end

    function obj = load(obj, use_schema)
      %
      % Loads schema
      %
      % USAGE::
      %
      %   schema = bids.Schema()
      %   schema = schema.load()
      %

      if nargin < 2
        use_schema = true();
      end

      schema_file = fullfile(bids.internal.root_dir(), 'schema.json');
      if ~exist(schema_file, 'file')
        msg = sprintf('The schema.json file %s does not exist.', schema_file);
        bids.internal.error_handling(mfilename(), 'missingSchema', msg, false, true);
      end

      obj.content = bids.util.jsondecode(schema_file);
      if ~use_schema
        obj.content = struct([]);
        return
      end

      % add extra field listing all required entities
      mod_grps = obj.return_modality_groups();

      datatypes = obj.get_datatypes();

      for i = 1:numel(mod_grps)

        mods = obj.return_modalities([], mod_grps{i});
        for j = 1:numel(mods)

          suffix_groups = obj.return_suffix_groups_for_datatype(mods{j});

          for k = 1:numel(suffix_groups)
            this_suffix_group = obj.ci_check(datatypes.(mods{j}).(suffix_groups{k}));
            required_entities = obj.required_entities_for_suffix_group(this_suffix_group);
            datatypes.(mods{j}).(suffix_groups{k}).required_entities = required_entities;
          end

        end
      end

      obj = obj.set_datatypes(datatypes);

    end

    function sts = eq(obj)
      sts = true;
    end

    function modalities = return_modalities(obj, subject, modality_group)
      %
      % Return the datatypes for a given for a given modality group for a given subject.
      % For example, "mri" will give: "func", "anat", "dwi", "fmap"...
      %
      % USAGE::
      %
      %   modalities = schema.return_modalities(subject, modality_group)
      %
      % :param subject:  Subject information: ``subject.path``, ...
      %                  See ``parse_subject`` subfunction for layout.m for details.
      % :type  subject:  struct
      %
      % :param modality_group:  Any of the BIDS modality
      % :type  modality_group:  char
      %
      % If we go schema-less, we list directories in the subject/session folder
      % as proxy of the datatypes that we have to parse.
      if isempty(obj.content)
        modalities = cellstr(bids.internal.file_utils('List', ...
                                                      subject.path, ...
                                                      'dir', ...
                                                      '.*'));
      else
        modalities = obj.content.rules.modalities.(modality_group).datatypes;

      end
    end

    % ----------------------------------------------------------------------- %
    %% DATATYPES
    function datatypes = get_datatypes(obj)
      datatypes = obj.content.rules.datatypes;
    end

    function obj = set_datatypes(obj, datatypes)
      obj.content.rules.datatypes = datatypes;
    end

    %% ENTITIES
    function order = entity_order(obj, varargin)
      %
      % Returns the 'correct' order for entities of entity list. If there are
      % non BIDS entities they are added after the BIDS ones in alphabetical
      % order.
      %
      % USAGE::
      %
      %     order = schema.entity_order(entity_list)
      %
      %
      % EXAMPLE::
      %
      %     schema = bids.Schema();
      %
      %     %  get the order of all the BIDS entities
      %     order = schema.entity_order()
      %
      %
      %     % reorder typical BIDS entities
      %     entity_list_to_order = {'description'
      %                             'run'
      %                             'subject'};
      %     order = schema.entity_order(entity_list_to_order)
      %
      %         {'subject'
      %          'run'
      %          'description'};
      %
      %     % reorder non-BIDS and typical BIDS entities
      %     entity_list_to_order = {'description'
      %                             'run'
      %                             'foo'
      %                             'subject'};
      %     order = schema.entity_order(entity_list_to_order)
      %
      %         {'subject'
      %          'run'
      %          'description'
      %          'foo'};
      %

      ischar_or_iscell = @(x) ischar(x) || iscellstr(x);

      if numel(varargin) == 1
        entity_list = varargin{1};
      elseif numel(varargin) == 0
        entity_list = fieldnames(obj.content.objects.entities);
      end

      assert(ischar_or_iscell(entity_list));

      if ischar(entity_list)
        entity_list = cellstr(entity_list);
      end

      order = obj.content.rules.entities;
      is_in_schema = ismember(order, entity_list);
      is_not_in_schema = ~ismember(entity_list, order);
      order = order(is_in_schema);
      order = cat(1, order, sort(entity_list(is_not_in_schema)));

    end

    function key = return_entity_key(obj, entity)
      %
      % Returns the key of an entity
      %
      % USAGE::
      %
      %     key = schema.return_entity_key(entity)
      %
      % EXAMPLE::
      %
      %     key = schema.return_entity_key('description')
      %
      %         'desc'
      %

      if ~ismember(entity, fieldnames(obj.content.objects.entities))
        msg = sprintf('No entity ''%s'' in schema.\n Available entities are:\n- ', ...
                      entity, ...
                      strjoin(fieldnames(obj.content.objects.entities), '\n- '));
        bids.internal.error_handling(mfilename, 'UnknownEnitity', msg, false);
      end

      key = obj.content.objects.entities.(entity).name;

    end

    %% MODALITIES
    function groups = return_modality_groups(obj)
      %
      % USAGE::
      %
      %   groups = schema.return_modality_groups()
      %
      %
      % Returns a dummy variable if we go schema less
      %

      groups = {nan()};
      if ~isempty(obj.content) && isfield(obj.content.objects, 'modalities')
        groups = fieldnames(obj.content.objects.modalities);
      end
    end

    % ----------------------------------------------------------------------- %
    %% SUFFIX GROUP

    function  suffix_groups = return_suffix_groups_for_datatype(obj, datatype)
      %
      % USAGE::
      %
      %  suffix_groups = schema.return_suffix_groups_for_datatype(datatype)
      %
      % :param datatype:
      % :type  datatype:  char
      %
      % EXAMPLE::
      %
      %  suffix_groups = schema.return_suffix_groups_for_datatype('func')
      %

      all_datatypes = obj.get_datatypes();
      suffix_groups = fieldnames(all_datatypes.(datatype));
    end

    function entities = return_entities_for_suffix_group(obj, suffix_group)
      % entities are returned in the expected order according to the schema
      %
      % USAGE::
      %
      %  entities = schema.return_entities_for_suffix_group(suffix_group)
      %
      % :param suffix_group:
      % :type  suffix_group:  struct
      %
      % EXAMPLE::
      %
      %  suffix_groups = return_suffix_groups_for_datatype(obj, datatype)
      %  entities = schema.return_entities_for_suffix_group(suffix_groups(1))
      %

      suffix_group = obj.ci_check(suffix_group);

      entity_names = fieldnames(suffix_group.entities);

      for i = 1:size(entity_names, 1)
        entities{1, i} = obj.content.objects.entities.(entity_names{i}).name; %#ok<*AGROW>
      end

    end

    function required_entities = required_entities_for_suffix_group(obj, this_suffix_group)
      %
      %  Returns a logical vector to track which entities of a suffix group
      %  are required in the bids schema
      %
      % :param this_suffix_group:
      % :type  this_suffix_group:  struct
      %
      % USAGE::
      %
      %  required_entities = schema.required_entities_for_suffix_group(this_suffix_group)
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

    function suffix_group = find_suffix_group(obj, modality, suffix)
      %
      % For a given sufffix and modality, this returns the "suffix group" this
      % suffix belongs to
      %
      % :param modality:
      % :type  modality:  char
      %
      % :param suffix:
      % :type  suffix:  char
      %
      % USAGE::
      %
      %  suffix_group = schema.find_suffix_group(modality, suffix)
      %
      % EXAMPLE::
      %
      %     schema = bids.Schema();
      %     suffix_group = schema.find_suffix_group('anat', 'T1w');
      %     suffix_group
      %
      %         'nonparametric'
      %

      suffix_group = '';

      if isempty(obj.content)
        return
      end

      datatypes = obj.get_datatypes();

      suffix_groups = obj.return_suffix_groups_for_datatype(modality);

      for i = 1:numel(suffix_groups)

        this_suffix_group = datatypes.(modality).(suffix_groups{i});
        this_suffix_group = obj.ci_check(this_suffix_group);
        if any(strcmp(suffix, this_suffix_group.suffixes))
          suffix_group = suffix_groups{i};
          break
        end
      end

      if strcmp(suffix_group, '')
        msg = sprintf('No corresponding suffix in schema for ''%s'' for datatype ''%s''\n', ...
                      suffix, ...
                      modality);
        bids.internal.error_handling(mfilename, 'noMatchingSuffix', msg, true, obj.verbose);
      end

    end

    % ----------------------------------------------------------------------- %
    %% SUFFIXES
    function datatypes = return_datatypes_for_suffix(obj, suffix)
      %
      % For a given suffix, returns all the possible datatypes that have this suffix.
      %
      % :param suffix:
      % :type  suffix:  char
      %
      % EXAMPLE::
      %
      %       schema = bids.Schema();
      %       datatypes = schema.return_datatypes_for_suffix('bold');
      %       assertEqual(datatypes, {'func'});
      %

      datatypes = {};

      if isempty(obj.content)
        return
      end

      all_datatypes = obj.get_datatypes();
      datatypes_names = fieldnames(all_datatypes);

      for i = 1:numel(datatypes_names)

        this_datatype = datatypes_names{i};

        % TODO deal with derivatives
        if strcmp(this_datatype, 'derivatives')
          continue
        end

        suffix_groups = obj.return_suffix_groups_for_datatype(this_datatype);

        for j = 1:numel(suffix_groups)

          this_suffix_group = suffix_groups{j};
          datatype_spec = obj.ci_check(all_datatypes.(this_datatype).(this_suffix_group));

          suffix_list = cat(1, datatype_spec.suffixes);

          if any(ismember(suffix_list, suffix))
            datatypes{end + 1} = this_datatype;
          end
        end

      end

      % in case we get duplicates
      datatypes = unique(datatypes);

    end

    function [entities, required] = return_entities_for_suffix_modality(obj, suffix, modality)
      %
      % returns the list of entities for a given suffix of a given modality
      %
      % :param modality:
      % :type  modality:  char
      %
      % :param suffix:
      % :type  suffix:  char
      %
      % USAGE::
      %
      %  [entities, required] = schema.return_entities_for_suffix_modality(suffix, modality)
      %

      suffix_group = obj.find_suffix_group(modality, suffix);

      datatypes = obj.get_datatypes();

      if ~isempty(suffix_group)
        this_suffix_group = datatypes.(modality).(suffix_group);
      end

      if ~isempty(suffix_group)
        required = obj.required_entities_for_suffix_group(this_suffix_group);
        entities = obj.return_entities_for_suffix_group(this_suffix_group);
      end
    end

    % ----------------------------------------------------------------------- %
    %% REGEX GENERATION
    function reg_ex = return_modality_suffixes_regex(obj, modality)
      %
      % creates a regular expression of suffixes for a given imaging modality
      %
      % :param modality:
      % :type  modality:  char
      %
      % USAGE::
      %
      %   reg_ex = schema.return_modality_suffixes_regex(modality)
      %

      reg_ex = obj.return_regex(modality, 'suffixes');
    end

    function reg_ex = return_modality_extensions_regex(obj, modality)
      %
      % creates a regular expression of extensions for a given imaging modality
      %
      % :param modality:
      % :type  modality:  char
      %
      % USAGE::
      %
      %   reg_ex = schema.return_modality_extensions_regex(modality)
      %

      reg_ex = obj.return_regex(modality, 'extensions');
    end

    function reg_ex = return_modality_regex(obj, modality)
      %
      % creates a regular expression of suffixes and extension for a given imaging modality
      %
      % :param modality:
      % :type  modality:  char
      %
      % USAGE::
      %
      %   reg_ex = schema.return_modality_regex(modality)
      %

      suffixes = obj.return_modality_suffixes_regex(modality);
      extensions = obj.return_modality_extensions_regex(modality);
      reg_ex = ['^%s.*' suffixes extensions '$'];
    end

    function [def, status] = get_definition(obj, word)
      %
      % finds definition of a column header in a the BIDS schema
      %
      % USAGE::
      %
      %   [def, status] = schema.get_definition(word)
      %

      status =  false;
      if ~isfield(obj.content.objects, 'metadata')
        obj.load_schema_metadata = true;
        obj = obj.load();
      end

      if isfield(obj.content.objects.columns, word)
        status = true;
        def = obj.content.objects.columns.(word);
      end

      if ~status && isfield(obj.content.objects.metadata, word)
        status = true;
        def = obj.content.objects.metadata.(word);
      end

      if ~status
        def = struct('LongName', word, ...
                     'Description', 'TODO', ...
                     'Units', 'TODO', ...
                     'TermURL', 'TODO');
      end

    end

  end

  % ----------------------------------------------------------------------- %
  %% STATIC
  methods (Static)

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
