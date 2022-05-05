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
  % (C) Copyright 2022 Remi Gau

  inputs = bids.transformers.get_input(transformer, data);
  outputs = bids.transformers.get_output(transformer, data);

  assert(numel(outputs) == 1);

  outputs = outputs{1};

  if isfield(transformer, 'Weights')
    weights = transformer.Weights;
  else
    weights = ones(size(inputs));
  end

  if isfield(transformer, 'OmitNan')
    omit_nan = transformer.OmitNan;
  else
    omit_nan = false;
  end

  tmp = [];

  for i = 1:numel(inputs)

    if ~isnumeric(data.(inputs{i}))
      error('non numeric variable: %s', inputs{i});
    end

    if ~isempty(tmp) && length(tmp) ~= length(data.(inputs{i}))
      error('trying to concatenate variables of different lengths: %s', inputs{i});
    end

    tmp(:, i) = data.(inputs{i}) * weights(i);

  end

  if omit_nan
    data.(outputs) = sum(tmp, 2, 'omitnan');

  else
    data.(outputs) = sum(tmp, 2);

  end

end
