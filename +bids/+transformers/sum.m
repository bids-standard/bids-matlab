function data = sum(transformer, data)
  %
  %
  % Computes the (optionally weighted) row-wise sums of two or more columns.
  % Arguments:
  % Input(list, mandatory): Names of two or more columns to sum.
  % Output(str, mandatory): Name of the newly generated column.
  % Weights(list, optional): Optional list of floats giving the weights of the columns.
  % If provided, length of weights must equal the number of values in input,
  % and weights will be mapped 1-to-1 onto named columns.
  % If no weights are provided, defaults to unit weights (i.e., simple sum).
  %
  % OmitNan
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  assert(numel(output) == 1);

  output = output{1};

  if isfield(transformer, 'Weights')
    weights = transformer.Weights;
  else
    weights = ones(size(input));
  end

  if isfield(transformer, 'OmitNan')
    omit_nan = transformer.OmitNan;
  else
    omit_nan = false;
  end

  tmp = [];

  for i = 1:numel(input)

    if ~isnumeric(data.(input{i}))
      error('non numeric variable: %s', input{i});
    end

    if ~isempty(tmp) && length(tmp) ~= length(data.(input{i}))
      error('trying to concatenate variables of different lengths: %s', input{i});
    end

    tmp(:, i) = data.(input{i}) * weights(i);

  end

  if omit_nan
    data.(output) = sum(tmp, 2, 'omitnan');

  else
    data.(output) = sum(tmp, 2);

  end

end
