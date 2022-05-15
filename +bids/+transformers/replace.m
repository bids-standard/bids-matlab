function data = replace(transformer, data)
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  % Replaces values in one or more input columns.

  % Arguments:

  % Input (list, mandatory):
  % Name(s_ of column(s) to search and replace within.

  % Replace (list of objects, mandatory):
  % An associative array (dictionary) mapping old values to new values.
  % For example,
  % [{"key": "apple", "value": "bee"}, {"key":"elusive", "value": 5}]
  % would replace all occurrences of "apple"
  % in the input columns with the value "bee", and all occurrences of "elusive"
  % with the value 5.

  % Attribute (string, optional):
  % The column attribute to search/replace. Valid values include "value" (the default),
  % "duration", "onset", and "all".
  % In the last case, all three attributes (value, duration, and onset) will be scanned.
  % Note that level names for categorical columns (e.g., "trial_type")
  % are invariably represented in the value attribute.
  %
  % Output (list, optional): Optional names of columns to output.
  % Must match length of input column(s) if provided,
  % and columns will be mapped 1-to-1 in order.
  % If no output values are provided, the replacement transformation is applied in-place
  % to all the inputs.

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  attributes =  get_attribute_to_replace(transformer);

  replace = transformer.Replace;

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    % in case we got "all" we must loop over value, onset, duration
    for ii = 1:numel(attributes)

      switch attributes{ii}

        case 'value'
          this_output = data.(output{i});

        case {'onset', 'duration'}
          this_output = data.(attributes{ii});
          if strcmp(input{i}, output{i})
            output{i} = attributes{ii};
          end

      end

      for iii = 1:numel(replace)

        switch attributes{ii}
          case 'value'
            this_input = data.(input{i});
          case {'onset', 'duration'}
            this_input = data.(attributes{ii});
        end

        key = replace(iii).key;
        value = replace(iii).value;

        if ischar(key)
          idx = strcmp(key, this_input);
        elseif isnumeric(key)
          idx = this_input == key;
        end

        if isnumeric(this_output)
          this_output(idx) = repmat(value, sum(idx), 1);

        elseif iscellstr(this_output)
          this_output(idx) = repmat({value}, sum(idx), 1);

        end

      end

      data.(output{i}) = this_output;
    end

  end

end

function attributes =  get_attribute_to_replace(transformer)
  attributes = {'value'};
  if isfield(transformer, 'Attribute')
    attributes = transformer.Attribute;
  end
  if ~ismember(attributes, {'value', 'onset', 'duration', 'all'})
    msg = sprintf(['Attribute must be one of ', ...
                   '"values", "onset", "duration" or "all" for Replace.\nGot: %s'], ...
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
    attributes =  {'values', 'onset', 'duration'};
  end
end
