function data = constant(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau
  outputs = bids.transformers.get_output(transformer);

  value = 1;
  if isfield(transformer, 'Value')
    value = transformer.Value;
  end

  data.(outputs{1}) = ones(size(data.onset)) * value;
end
