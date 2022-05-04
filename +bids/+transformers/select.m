function data = select(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);

  for i = 1:numel(inputs)
    tmp.(inputs{i}) = data.(inputs{i});
  end

  data = tmp;
end
