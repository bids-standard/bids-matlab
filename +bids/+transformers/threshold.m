function data = threshold(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau

  % Thresholds input values at a specified cut-off and optionally binarizes the result.

  % Arguments:

  % Input(list, mandatory):
  % The name(s)of the column(s) to threshold/binarize.

  % Threshold(float, optional):
  % The cut-off to use for thresholding.
  % Defaults to 0.

  % Binarize(boolean, optional):
  % If True, thresholded values will be binarized (i.e., all non-zero values will be set to 1).
  % Defaults to False.

  % Above(boolean, optional):
  % Specifies which values to retain with respect to the cut-off.
  % If True, all value above the threshold will be kept;
  % if False, all values below the threshold will be kept.
  % Defaults to True.

  % Signed(boolean, optional):
  % Specifies whether to treat the threshold as signed (default) or unsigned.
  %
  % For example, when passing above=True and threshold=3,
  % if signed=True, all and only values above +3 would be retained.
  % If signed=False, all absolute values > 3 would be retained
  % (i.e.,values in  the range -3 < X < 3 would be set to 0).
  %
  % Output(list, optional): Optional names of columns to output.
  % Must match length of input column if provided,
  % and columns will be mapped 1-to-1 in order.
  % If no output values are provided, the threshold transformation is applied
  % in-place to all the inputs.

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

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

  for i = 1:numel(input)

    valuesToThreshold = data.(input{i});

    if ~signed
      valuesToThreshold = abs(valuesToThreshold);
    end

    if above
      idx = valuesToThreshold > threshold;
    else
      idx = valuesToThreshold < threshold;
    end

    tmp = zeros(size(data.(input{i})));
    tmp(idx) = data.(input{i})(idx);

    if binarize
      tmp(idx) = 1;
    end

    data.(output{i}) = tmp;
  end

end
