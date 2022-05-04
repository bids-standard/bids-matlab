function data = delete(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);

  for i = 1:numel(inputs)
    if isfield(data, inputs{i})
      data = rmfield(data, inputs{i});
    end
  end
end
