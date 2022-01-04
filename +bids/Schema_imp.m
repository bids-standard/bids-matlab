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
    version
    content
    modalities
  end

  methods
    function obj = Schema_imp(vesion)
      if nargin < 1
        obj.version = '1.6.0';
      else
        obj.version = version;
      end

      schema_dir = fullfile(bids.internal.root_dir(), 'schema');
      schema_file = ['schema_entities_v', obj.version, '.json'];
      schema_path = fullfile(schema_dir, schema_file);
      if ~exist(schema_path, 'file')
        msg = sprintf('Unsupported schema version: %s', obj.version);
        bids.internal.error_handling(mfilename(), 'missingFile', msg, false, true);
      end

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
  end
end
