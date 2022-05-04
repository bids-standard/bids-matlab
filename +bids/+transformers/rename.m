function data = rename(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);
  outputs = bids.transformers.get_output(transformer);

  for i = 1:numel(inputs)
    data.(outputs{i}) = data.(inputs{i});
    data = rmfield(data, inputs{i});
  end

end
