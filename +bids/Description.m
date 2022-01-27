classdef Description
  %
  % Class to deal with dataset_description files.
  %
  % USAGE::
  %
  %   ds_desc = bids.Description(pipeline, BIDS);
  %
  % :param pipeline: pipeline name
  % :type  pipeline: string
  % :param BIDS: output from BIDS layout to identify the source dataset
  %              used when creating a derivatives dataset
  % :type  BIDS: structure
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  % TODO
  % - transfer validate function of layout in here

  properties

    content % dataset description content

    is_derivative = false % boolean

    pipeline = '' % name of the pipeline used to generate this derivative dataset

    source_description = struct([])

  end

  methods

    function obj = Description(pipeline, BIDS)
      %
      % Instance constructor
      %

      if nargin > 0
        obj.is_derivative = true;
        if ~isempty(pipeline)
          obj.pipeline = pipeline;
        end
      end

      if nargin > 1 && ~isempty(BIDS)
        obj.source_description = BIDS.description;
      end

      obj.content = struct( ...
                           'Name', '', ...
                           'BIDSVersion', '', ...
                           'DatasetType', 'raw', ...
                           'License', '', ...
                           'Acknowledgements', '', ...
                           'HowToAcknowledge', '', ...
                           'DatasetDOI', '', ...
                           'HEDVersion', '', ...
                           'Funding', {{}}, ...
                           'Authors', {{}}, ...
                           'ReferencesAndLinks', {{}});

      obj = set_derivative(obj);

    end

    function obj = set_derivative(obj)
      %
      % USAGE::
      %
      %  ds_desc = ds_desc.set_derivative();
      %

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
      %
      % USAGE::
      %
      %  ds_desc = ds_desc.set_field(key, value);
      %  ds_desc = ds_desc.set_field(struct(key1, value1, ...
      %                                     key2, value2));
      %

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
      %
      % Appends an item to the dataset description content.
      %
      % USAGE::
      %
      %  ds_desc = ds_desc.append(key, value);
      %

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
      %
      % Writes json file of the dataset description.
      %
      % USAGE::
      %
      %  ds_desc.write([folder = pwd]);
      %

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
