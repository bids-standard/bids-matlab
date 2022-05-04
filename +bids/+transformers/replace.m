function tsv_content = replace(transformer, tsv_content)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);
  outputs = bids.transformers.get_output(transformer);

  attributes =  get_attribute_to_replace(transformer);

  replace = transformer.Replace;

  for i = 1:numel(inputs)

    if ~isfield(tsv_content, inputs{i})
      continue
    end

    for ii = 1:numel(attributes)

      switch lower(attributes{ii})
        case 'value'
          if strcmp(inputs{i}, outputs{i})
            this_output = tsv_content.(inputs{i});
          else
            this_output = tsv_content.(outputs{i});
          end
        case 'onset'
          this_output = tsv_content.onset;
          if strcmp(inputs{i}, outputs{i})
            outputs{i} = 'onset';
          end
        case 'duration'
          this_output = tsv_content.duration;
          if strcmp(inputs{i}, outputs{i})
            outputs{i} = 'duration';
          end
      end

      toReplace = fieldnames(replace);

      for iii = 1:numel(toReplace)

        switch lower(attributes{ii})
          case 'value'
            this_input = tsv_content.(inputs{i});
          case 'onset'
            this_input = tsv_content.onset;
          case 'duration'
            this_input = tsv_content.duration;
        end

        key = get_key_to_replace(inputs{i}, attributes{ii}, toReplace{iii});
        value = replace.(toReplace{iii});

        if ischar(key)
          idx = strcmp(key, this_input);
        elseif isnumeric(key)
          idx = this_input == key;
        end

        if isnumeric(this_output)
          if ischar(value)
            this_output = num2cell(this_output);
          end
          this_output(idx) = value;

        elseif iscellstr(this_output)
          if isnumeric(value)
            value = num2str(value);
          end
          this_output(idx) = repmat({value}, sum(idx), 1);

        end

      end

      tsv_content.(outputs{i}) = this_output;
    end

  end

end

function key = get_key_to_replace(input, attribute, to_replace)
  % because matlab keys in structure cannot be numbers
  % it won't be easily possible to replace
  % when the value to replace is a number,
  % but it could be sort of OK for onset and duration
  key = to_replace;
  if ismember(lower(attribute), {'onset', 'duration'})
    key = strrep(key, [lower(attribute) '_'], '');
    key = str2num(key);
  end
  if bids.internal.starts_with(key, [input '_'])
    key = strrep(key, [input '_'], '');
    key = str2num(key);
  end

end

function attributes =  get_attribute_to_replace(transformer)
  attributes = {'value'};
  if isfield(transformer, 'Attribute')
    attributes = transformer.Attribute;
  end
  if ~iscell(attributes)
    attributes = {attributes};
  end
  if strcmp(attributes, 'all')
    attributes =  {'values', 'onset', 'duration'};
  end
end
