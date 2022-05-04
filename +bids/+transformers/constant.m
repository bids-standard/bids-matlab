function tsv_content = constant(transformer, tsv_content)
  %
  %
  % (C) Copyright 2022 Remi Gau
  outputs = bids.transformers.get_output(transformer);

  value = 1;
  if isfield(transformer, 'Value')
    value = transformer.Value;
  end

  tsv_content.(outputs{1}) = ones(size(tsv_content.onset)) * value;
end
