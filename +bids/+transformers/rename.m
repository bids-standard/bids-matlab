function tsv_content = rename(transformer, tsv_content)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);
  outputs = bids.transformers.get_output(transformer);

  for i = 1:numel(inputs)
    tsv_content.(outputs{i}) = tsv_content.(inputs{i});
    tsv_content = rmfield(tsv_content, inputs{i});
  end

end
