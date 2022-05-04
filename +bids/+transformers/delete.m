function tsv_content = delete(transformer, tsv_content)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);

  for i = 1:numel(inputs)
    if isfield(tsv_content, inputs{i})
      tsv_content = rmfield(tsv_content, inputs{i});
    end
  end
end
