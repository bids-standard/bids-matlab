classdef dataset_description

  properties
    content
    is_derivative
  end

  methods

    function obj = generate(obj, is_derivative)

      if nargin < 2 || isempty(is_derivative)
        is_derivative = false;
      end

      obj.content = struct( ...
                           'Name', '', ...
                           'BIDSVersion', '', ...
                           'DatasetType', 'raw', ...
                           'License', '', ...
                           'Authors', '', ...
                           'Acknowledgement', '', ...
                           'HowToAcknowledge', '', ...
                           'Funding', '', ...
                           'ReferencesAndLinks', '', ...
                           'DatasetDOI', '', ...
                           'HEDVersion', '');

      obj.is_derivative = is_derivative;

      obj = set_derivative(obj);

    end

    function obj = set_derivative(obj)

      if obj.is_derivative

        obj = set_field(obj, 'DatasetType', 'derivative');

        obj = set_field(obj, 'GeneratedBy',  struct( ...
                                                    'Name', '', ...
                                                    'Version', '', ...
                                                    'Container', struct('Type', '', 'Tag', '')));

        obj = set_field(obj, 'SourceDatasets', struct( ...
                                                      'DOI', '', ...
                                                      'URL', '', ...
                                                      'Version', ''));

      end

    end

    function obj = set_field(obj, key, value)
      obj.content(1).(key) = value;
    end
    
    function obj = append(obj, key, value)
      obj.content(1).(key) = value;
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
