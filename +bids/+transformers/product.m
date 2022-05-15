function data = product(transformer, data)
  %
  %
  % Product(Input, Output)
  % Computes the row-wise product of two or more columns.
  % Arguments:
  % Input(list, mandatory): Names of two or more columns to compute the product of.
  % Output(str, mandatory): Name of the newly generated column.
  %
  %
  % OmitNan
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  assert(numel(output) == 1);

  output = output{1};

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

    tmp(:, i) = data.(input{i});

  end

  if omit_nan
    data.(output) = prod(tmp, 2, 'omitnan');

  else
    data.(output) = prod(tmp, 2);

  end

end
