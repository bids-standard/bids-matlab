function data = rename(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  assert(numel(input) == numel(output));

  for i = 1:numel(input)
    data.(output{i}) = data.(input{i});
    data = rmfield(data, input{i});
  end

end
