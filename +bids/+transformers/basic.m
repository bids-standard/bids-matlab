function data = basic(transformer, data)
  %
  % USAGE::
  %
  %   data = bids.transformers.basic(transformer, data)
  %
  % Perfoms a basic operation with a ``Value`` on the ``Input``::
  %
  %   Add(Input, Value, [Output])
  %   Divide(Input, Value, [Output])
  %   Multiply(Input, Value, [Output])
  %   Subtract(Input, Value, [Output])
  %   Power(Input, Value, [Output])
  %
  % Each of these transformations takes one or more columns,
  % and performs a mathematical operation on the input column and a provided operand.
  % The operations are performed on each column independently.
  %
  % Arguments:
  %
  % - Input(array; mandatory): A list of columns to perform operation on.
  % - Value(float or str; mandatory): The value to perform operation with (i.e. operand)
  % - Output(array; optional): the optional list of column names to write out to.
  %
  % By default, computation is done in-place on the inputs (i.e., input columns are overwritten).
  % If provided, the number of values must exactly match the number of input values,
  % and the order will be mapped 1-to-1.
  %
  % (C) Copyright 2022 Remi Gau

  inputs = bids.transformers.get_input(transformer, data);
  outputs = bids.transformers.get_output(transformer, data);

  for i = 1:numel(inputs)

    value = transformer.Value;

    if ischar(value)
      value = str2double(value);
      if isnan(value)
        msg = sprintf('basic transformers require values convertable to numeric. Got: %s', ...
                      transformer.Value);
        bids.internal.error_handling(mfilename(), ...
                                     'numericOrCoercableToNumericRequired', ...
                                     msg, ...
                                     false);
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
