classdef dataset_description
  %
  % Class to deal with dataset_description files.
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  % TODO
  % - transfer validate function of layout in here

  properties
    content
    is_derivative = false
    pipeline = ''
    source_description = struct([])
  end

  methods

    function obj = generate(obj, pipeline, BIDS)

      if nargin > 1
        obj.is_derivative = true;
        if ~isempty(pipeline)
          obj.pipeline = pipeline;
        end
      end

      if nargin > 2 && ~isempty(BIDS)
        obj.source_description = BIDS.description;
      end

      obj.content = struct( ...
                           'Name', '', ...
                           'BIDSVersion', '', ...
                           'DatasetType', 'raw', ...
                           'License', '', ...
                           'Authors', '', ...
                           'Acknowledgements', '', ...
                           'HowToAcknowledge', '', ...
                           'Funding', '', ...
                           'ReferencesAndLinks', '', ...
                           'DatasetDOI', '', ...
                           'HEDVersion', '');

      obj = set_derivative(obj);

    end

    function obj = set_derivative(obj)

      if obj.is_derivative

        obj = set_field(obj, 'DatasetType', 'derivative');

        obj = set_field(obj, 'GeneratedBy',  {struct( ...
                                                     'Name', obj.pipeline, ...
                                                     'Version', '', ...
                                                     'Description', '', ...
                                                     'CodeURL', '', ...
                                                     'Container', struct('Type', '', 'Tag', ''))
                                             });

        doi_source_data = '';
        if isfield(obj.source_description, 'DatasetDOI')
          doi_source_data = obj.source_description.DatasetDOI;
        end

        obj = set_field(obj, 'SourceDatasets', {struct( ...
                                                       'DOI', doi_source_data, ...
                                                       'URL', '', ...
                                                       'Version', '')
                                               });

      end

    end

    function obj = set_field(obj, varargin)

      if numel(varargin) == 2
        key = varargin{1};
        value = varargin{2};
        obj.content(1).(key) = value;

      elseif numel(varargin) == 1 && isstruct(varargin{1})
        fields = fieldnames(varargin{1});
        for iField = 1:numel(fields)
          key = fields{iField};
          value = varargin{1}.(key);
          obj = set_field(obj, key, value);
        end

      end
    end

    function obj = append(obj, key, value)

      if ~isfield(obj.content, key)
        new_value = value;

      else
        old_value = obj.content(1).(key);
        if ischar(old_value)
          new_value = {old_value};
        else
          new_value = old_value;
        end
        if ~iscell(new_value) && isstruct(value)
          new_value = {new_value};
        end
        new_value{end + 1, 1} = value;

      end

      obj = set_field(obj, key, new_value);
    end

    function obj = unset_field(obj, key)
      obj.content = rmfield(obj.content, key);
    end

    function write(obj, folder)

      if nargin < 2 || isempty(folder)
        folder = pwd;
      end

      opts.Indent = '    ';

      fileName = fullfile(folder, 'dataset_description.json');

      json_content = obj.content;

      bids.util.jsonencode(fileName, json_content, opts);

    end

  end

end
