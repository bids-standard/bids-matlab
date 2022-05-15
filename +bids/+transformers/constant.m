function data = constant(transformer, data)
  %
  % USAGE::
  %
  %   data = constant(transformer, data)
  %
  % Adds a new column with a constant value.
  %
  % Arguments:
  %
  % - Output(str; mandatory): Name of the newly generated column.
  % - Value(float; optional): The value of the constant, defaults to 1.
  %
  % (C) Copyright 2022 Remi Gau
  output = bids.transformers.get_output(transformer, data);

  assert(numel(output) == 1);

  value = 1;
  if isfield(transformer, 'Value')
    value = transformer.Value;
  end

  data.(output{1}) = ones(size(data.onset)) * value;
end
