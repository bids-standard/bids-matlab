function data = basic(transformer, data)
  %
  % USAGE::
  %
  %   data = bids.transformers.basic(transformer, data)
  %
  % Perfoms a basic operation with a Value on the Data::
  %
  %  Add(Data, Value, [Output])
  %  Divide(Data, Value, [Output])
  %  Multiply(Data, Value, [Output])
  %  Subtract(Data, Value, [Output])
  %  Power(Data, Value=2, [Output])
  %
  % If no Output is specified the Data is modified in place
  %
  % (C) Copyright 2022 Remi Gau

  inputs = bids.transformers.get_input(transformer);
  outputs = bids.transformers.get_output(transformer);

  for i = 1:numel(inputs)

    if ~isfield(data, inputs{i})
      % TODO throw warning
      continue
    end

    % all basic transformers require a Value except for Power that default to 2
    if ~strcmpi(transformer.Name, 'power')
      value = transformer.Value;
    else
      if isfield(transformer, 'Value')
        value = transformer.Value;
      else
        value = 2;
      end
    end

    assert(isnumeric(value));

    switch lower(transformer.Name)

      case 'add'
        tmp = data.(inputs{i}) + value;

      case 'subtract'
        tmp = data.(inputs{i}) - value;

      case 'multiply'
        tmp = data.(inputs{i}) * value;

      case 'divide'
        tmp = data.(inputs{i}) / value;

      case 'power'
        tmp = data.(inputs{i}).^value;

    end

    data.(outputs{i}) = tmp;

  end

end
