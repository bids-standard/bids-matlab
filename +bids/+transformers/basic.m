function tsv_content = basic(transformer, tsv_content)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);
  outputs = bids.transformers.get_output(transformer);

  transformerName = lower(transformer.Name);

  for i = 1:numel(inputs)

    if ~isfield(tsv_content, inputs{i})
      continue
    end

    value = transformer.Value;

    switch transformerName

      case 'add'
        tmp = tsv_content.(inputs{i}) + value;

      case 'subtract'
        tmp = tsv_content.(inputs{i}) - value;

      case 'multiply'
        tmp = tsv_content.(inputs{i}) * value;

      case 'divide'
        tmp = tsv_content.(inputs{i}) / value;

    end

    tsv_content.(outputs{i}) = tmp;

  end

end
