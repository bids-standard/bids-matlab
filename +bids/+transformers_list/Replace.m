function data = Replace(transformer, data)
  %
  % Replaces values in one or more input columns.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "Replace",
  %       "Input": [
  %           "fruits",
  %       ],
  %       "Replace": [
  %               {"key": "apple",   "value": "bee"},
  %               {"key": "elusive", "value": 5},
  %               {"key": -1, "value": 0}]
  %        ],
  %        "Attribute": "all"
  %     }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. Name(s of column(s) to search and replace within.
  % :type  Input: string or array
  %
  % :param Replace: **mandatory**. The mapping old values (``"key"``) to new values.
  %                                (``"value"``)
  % :type  Replace: array of objects
  %
  % :param Attribute: optional. The column attribute to search/replace.
  % :type  Attribute: array
  %
  % Valid values include:
  %
  % - ``"value"`` (the default),
  % - ``"duration"``,
  % - ``"onset"``,
  % - and ``"all"``.
  %
  % In the last case, all three attributes
  % (``"value"``, ``"duration"``, and ``"onset"``) will be scanned.
  %
  % :param Output: optional. Optional names of columns to output.
  %                          Must match length of input column(s) if provided,
  %                          and columns will be mapped 1-to-1 in order.
  %                          If no output values are provided,
  %                          the replacement transformation is applied in-place
  %                          to all the inputs.
  % :type  Output: string or array
  %
  %
  % **CODE EXAMPLE**::
  %
  %
  %     data.fruits = {'apple'; 'banana'; 'elusive'};
  %     data.onset = {1; 2; 3};
  %     data.duration = {-1; 1; 3};
  %
  %     replace = struct('key', {'apple'; 'elusive'}, 'value', -1);
  %     replace(end+1).key = -1;
  %     replace(end).value = 0;
  %
  %     transformer = struct('Name', 'Replace', ...
  %                          'Input', 'fruits', ...
  %                          'Atribute', 'all', ...
  %                          'Replace', replace);
  %
  %
  %
  %     data = bids.transformers(transformer, data);
  %
  %
  %   data.
  %
  %   ans =
  %
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data);

  attributes =  get_attribute_to_replace(transformer);

  replace = transformer.Replace;

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    for ii = 1:numel(replace)

      this_input = data.(input{i});

      key = replace(ii).key;

      if ischar(key) && iscellstr(this_input)
        idx = strcmp(key, this_input);
      elseif isnumeric(key) && isnumeric(this_input)
        idx = this_input == key;
      elseif ischar(key) && iscell(this_input)
        idx = cellfun(@(x) ischar(x) && strcmp(x, key), this_input);
      elseif isnumeric(key) && iscell(this_input)
        idx = cellfun(@(x) isnumeric(x) && x == key, this_input);
      else
        continue
      end

      value = replace(ii).value;

      data = replace_for_attributes(data, attributes, output{i}, this_input, idx, value);

    end

  end

end

function [this_output, output] = get_this_output(data, attr, output, this_input)

  switch attr

    case 'value'
      if isfield(data, output)
        this_output = data.(output);
      else
        this_output = this_input;
      end

    case {'onset', 'duration'}
      output = attr;
      this_output = data.(attr);

  end

end

function data = replace_for_attributes(data, attributes, output, this_input, idx, value)

  % in case we got "all" we must loop over value, onset, duration
  for i = 1:numel(attributes)

    [this_output, output] = get_this_output(data, attributes{i}, output, this_input);

    if isnumeric(this_output)
      this_output(idx) = repmat(value, sum(idx), 1);

    elseif iscellstr(this_output)
      this_output(idx) = repmat({value}, sum(idx), 1);

    elseif iscell(this_output)
      this_output(idx) = repmat({value}, sum(idx), 1);

    end

    data.(output) = this_output;

  end

end

function attributes =  get_attribute_to_replace(transformer)
  attributes = {'value'};
  if isfield(transformer, 'Attribute')
    attributes = transformer.Attribute;
  end
  if ~ismember(attributes, {'value', 'onset', 'duration', 'all'})
    msg = sprintf(['Attribute must be one of ', ...
                   '"value", "onset", "duration" or "all" for Replace.\nGot: %s'], ...
                  char(attributes));
    bids.internal.error_handling(mfilename(), ...
                                 'invalidAttribute', ...
                                 msg, ...
                                 false);
  end
  if ~iscell(attributes)
    attributes = {attributes};
  end
  if strcmpi(attributes, 'all')
    attributes =  {'value', 'onset', 'duration'};
  end
end
