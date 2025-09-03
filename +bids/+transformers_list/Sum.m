function data = Sum(transformer, data)
  %
  % Computes the (optionally weighted) row-wise sums of two or more columns.
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. Names of two or more columns to sum.
  % :type  Input: array
  %
  % :param Output: **mandatory**. Name of the newly generated column.
  % :type  Output: char or array
  %
  % :param OmitNan: Optional. If ``false`` any column with nan values will return a nan value.
  %                           If ``true`` nan values are skipped. Defaults to ``false``.
  % :type  OmitNan: logical
  %
  % :param Weights: Optional. Optional array of floats giving the weights of the columns.
  %                           If provided, length of weights must equal
  %                           to the number of values in input,
  %                           and weights will be mapped 1-to-1 onto named columns.
  %                           If no weights are provided,
  %                           defaults to unit weights (i.e., simple sum).
  % :type  Weights: array
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  if any(~ismember(input, fieldnames(data)))
    return
  end

  output = bids.transformers_list.get_output(transformer, data);

  assert(isscalar(output));

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
