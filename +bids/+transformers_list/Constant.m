function data = Constant(transformer, data)
  %
  % Adds a new column with a constant value (numeric or char).
  %
  % Arguments:
  %
  % :param Output: **mandatory**. Name of the newly generated column.
  % :type  Output: char or array
  %
  % :param Value: Optional. The value of the constant, defaults to ``1``.
  % :type  Value: float or char
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  output = bids.transformers_list.get_output(transformer, data);

  assert(isscalar(output));

  value = 1;
  if isfield(transformer, 'Value')
    value = transformer.Value;
  end

  a = structfun(@(x) size(x, 1), data, 'UniformOutput', false);
  nb_rows = max(cell2mat(struct2cell(a)));
  if isnumeric(value)
    data.(output{1}) = ones(nb_rows, 1) * value;
  elseif ischar(value)
    data.(output{1}) = cellstr(repmat(value, nb_rows, 1));
  end

end
