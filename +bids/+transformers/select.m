function data = select(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau
  input = bids.transformers.get_input(transformer, data);

  for i = 1:numel(input)
    tmp.(input{i}) = data.(input{i});
  end

  data = tmp;
end
