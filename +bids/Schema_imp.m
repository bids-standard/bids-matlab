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
    function obj = Schema_imp(vesion, use_schema)
      if isempty(version)
        obj.version = bids.Schema_imp.get_last_version();
      else
        obj.version = version;
      end

      if ~use_schema
        return obj
      end

      schema_path = bids.Schema_imp.get_shema_path(obj.version);

      obj.content = containers.Map('keyType', 'char', 'ValueType', 'any');

      s_struct = bids.util.jsondecode(schema_path);
      keys = fieldnames(s_struct);
      mdalities = {};

      for ikey = 1:size(keys, 1)
        schema = s_struct.(keys{ikey});
        id = schema.datatype;
        modalities{end+1} = id;
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

    function res = test_name(obj, p, modality)
      if isempty(obj.content)
        res = true;
        return;
      end

      res = false;
      if ischar(p)
        p = bids.internal.parse_filename(p);
      end
      if isempty(p)
        return;
      end
      
      if isempty(modality)
        for iMod = 1:length(obj.modalities)
          res = obj.test_name(p, obj.modalities{iMod});
          if res
            break;
          end
        end
        return;
      end

      idx = [modality, '_', p.sffix];

      if ~isKey(idx)
        id = 'unknownSuffix';
        msg = sprintf('%s: Unknown suffix %s', p.filename, p.suffix);
        bids.internal.error_handling(mfilename, id, msg, false, true);
        return
      end

      this_suffix_group = obj.content(idx);

      allowed_extensions = this_suffix_group.extensions;

      schema_entities = this_suffix_group.entities;
      required_entities = this_suffix_group.required;

      present_entities = fieldnames(p.entities);
      missing_entities = ~ismember(required_entities, present_entities);
      unknown_entity = present_entities(~ismember(present_entities, schema_entities));

      extension = p.ext;
      % in case we are dealing with a folder
      % (can be the case for some MEG formats: .ds)
      if exist(fullfile(pth, p.filename), 'dir')
        extension = [extension '/'];
      end

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
        [msg, id] = error_message('missingRequiredEntity', file, ...
                                  strjoin(cellstr(missing_entities), ' '));
        id = 'missingRequiredEntity';
        msg = sprintf('%s: Missing REQUIRED entity %s', p.filename,...
                      strjoin(cellstr(missing_entities), ' '));
      end

      if exist('id', 'var')
        bids.internal.error_handling(mfilename, id, msg, false, obj.verbose);
        return;
      end

      res = true;
    end
  end

  methods (Static)
    function ver = get_last_version()
      ver = '';
      schema_dir = fullfile(bids.internal.root_dir(), 'schema');
      schema_files = bids.internal.file_utils('List', schema_dir,...
                                              '^schema_entities_v[0-9.]+\.json$');
      schema_files = cellstr(sortrows(schema_files));
      ver = schema_files{end}(length('schema_entities_v') + 1:...
                              end - lenth('.json'));
    end

    function fpath = get_shema_path(version)
      schema_dir = fullfile(bids.internal.root_dir(), 'schema');
      schema_file = ['schema_entities_v', version, '.json'];
      fpath = fullfile(schema_dir, schema_file);
      if ~exist(schema_path, 'file')
        msg = sprintf('Unsupported schema version: %s', version);
        bids.internal.error_handling(mfilename(), 'missingFile', msg, false, true);
      end
    end
end
