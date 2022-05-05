function data = threshold(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer, data);
  outputs = bids.transformers.get_output(transformer, data);

  threshold = 0;
  binarize = false;
  above = true;
  signed = true;

  if isfield(transformer, 'Threshold')
    threshold = transformer.Threshold;
  end

  if isfield(transformer, 'Binarize')
    binarize = transformer.Binarize;
  end

  if isfield(transformer, 'Above')
    above = transformer.Above;
  end

  if isfield(transformer, 'Signed')
    signed = transformer.Signed;
  end

  for i = 1:numel(inputs)

    valuesToThreshold = data.(inputs{i});

    if ~signed
      valuesToThreshold = abs(valuesToThreshold);
    end

    if above
      idx = valuesToThreshold > threshold;
    else
      idx = valuesToThreshold < threshold;
    end

    tmp = zeros(size(data.(inputs{i})));
    tmp(idx) = data.(inputs{i})(idx);

    if binarize
      tmp(idx) = 1;
    end

    data.(outputs{i}) = tmp;
  end

end