classdef Schema_imp
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

  properties
    version = ''
    content = []
    modalities = []
  end

  methods
    function obj = Schema_imp(version, use_schema)
      if isempty(version)
        obj.version = bids.Schema_imp.get_last_version();
      else
        obj.version = version;
      end

      obj.content = containers.Map('keyType', 'char', 'ValueType', 'any');

      if ~use_schema
        return
      end

      schema_path = bids.Schema_imp.get_schema_path(obj.version);

      s_struct = bids.util.jsondecode(schema_path);
      keys = fieldnames(s_struct);
      modalities = {};

      for ikey = 1:size(keys, 1)
        schema = s_struct.(keys{ikey});
        id = schema.datatype;
        modalities{end+1, 1} = id; %#ok<AGROW>
        rules.extensions = schema.extensions;
        rules.entities = schema.entities;
        rules.required = schema.required;
        for i_suf =  1:size(schema.suffixes, 1)
          id_loc = [id, '_', schema.suffixes{i_suf}];
          obj.content(id_loc) = rules;
        end
      end 
      obj.modalities = unique(modalities);
    end

    function res = has_schema(obj)
      res = (~isempty(obj.content));
    end

    function [res, rules] = test_name(obj, p, modality)
      rules = [];
      if isempty(obj.content)
        res = true;
        return;
      end

      res = false;
      if ischar(p)
        p = bids.internal.parse_filename(p);
      end

      if isempty(p)
        id = 'emptyFileStructure';
        msg = sprintf('File structure is empty');
        bids.internal.error_handling(mfilename, id, msg, false, true);
        return;
      end

      idx = [modality, '_', p.suffix];

      if ~obj.content.isKey(idx)
        id = 'unknownSuffix';
        msg = sprintf('%s: Unknown suffix %s for modality %s',...
                      p.filename, p.suffix, modality);
        bids.internal.error_handling(mfilename, id, msg, false, true);
        return
      end

      this_suffix_group = obj.content(idx);
      rules = this_suffix_group;

      allowed_extensions = this_suffix_group.extensions;

      schema_entities = this_suffix_group.entities;
      required_entities = this_suffix_group.required;

      present_entities = fieldnames(p.entities);
      missing_entities = ~ismember(required_entities, present_entities);
      unknown_entity = present_entities(~ismember(present_entities,...
                                        schema_entities));

      extension = p.ext;

      %% Checks that this file is BIDS compliant
      if ~ismember('*', allowed_extensions) && ...
              ~ismember(extension, allowed_extensions)
        id = 'unknownExtension';
        msg = sprintf('%s: Unknown extension %s', p.filename, extension);
      end

      if ~isempty(unknown_entity)
        id = 'unknownEntity';
        msg = sprintf('%s: Unknown entity %s', p.filename,...
                      strjoin(cellstr(unknown_entity), ' '));
      end

      if any(missing_entities)
        missing_entities = required_entities(missing_entities);
        id = 'missingRequiredEntity';
        msg = sprintf('%s: Missing REQUIRED entity %s', p.filename,...
                      strjoin(cellstr(missing_entities), ' '));
      end

      if exist('id', 'var')
        bids.internal.error_handling(mfilename, id, msg,...
                                     false, true);
        return;
      end

      res = true;
    end

    function datatypes = return_datatypes_for_suffix(obj, suffix)

      keys = obj.content.keys();
      datatypes = cellfun(@(x) tokenize(x, '_'),...
                          keys, 'UniformOutput', false);
      index = cellfun(@(x) strcmp(x{end}, suffix),...
                      datatypes, 'UniformOutput', 1);
      datatypes = datatypes(index);
      datatypes = cellfun(@(x) strjoin(x(1:end-1), '_'),...
                          datatypes, 'UniformOutput', false);
    end

  end

  methods (Static)
    function ver = get_last_version()
      schema_dir = fullfile(bids.internal.root_dir(), 'schema');
      schema_files = bids.internal.file_utils('List', schema_dir,...
                                              '^schema_entities_v[0-9.]+\.json$');
      schema_files = cellstr(sortrows(schema_files));
      ver = bids.Schema_imp.get_version_from_name(schema_files{end});
    end

    function fpath = get_schema_path(version)
      schema_dir = fullfile(bids.internal.root_dir(), 'schema');
      schema_file = ['schema_entities_v', version, '.json'];
      fpath = fullfile(schema_dir, schema_file);
      if exist(fpath, 'file') ~= 2
        msg = sprintf('Unsupported schema version: %s', version);
        bids.internal.error_handling(mfilename(), 'missingFile', msg,...
                                     false, true);
      end
    end

    function versions = get_version_list()
      schema_dir = fullfile(bids.internal.root_dir(), 'schema');
      schema_files = bids.internal.file_utils('List', schema_dir,...
                                              '^schema_entities_v[0-9.]+\.json$');
      schema_files = cellstr(sortrows(schema_files));
      versions = cellfun(@bids.Schema_imp.get_version_from_name, schema_files, ...
                         'UniformOutput',false);   
    end

    function ver = get_version_from_name(name)
      prefix_len = length('schema_entities_v');
      ext_len = length('json');
      ver = name(prefix_len + 1: end - ext_len - 1);
    end

    function regex = generate_regex(list, type)
      regex = ['(' strjoin(list, '|') ')'];
      if strcmp(type, 'suffix')
        regex = ['_' regex '{1}'];
      elseif strcmp(type, 'extension')
        regex = [regex '{1}$']
      end
    end
  end
end
