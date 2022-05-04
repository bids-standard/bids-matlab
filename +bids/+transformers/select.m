function tsv_content = select(transformer, tsv_content)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);

  for i = 1:numel(inputs)
    tmp.(inputs{i}) = tsv_content.(inputs{i});
  end

  tsv_content = tmp;
end
