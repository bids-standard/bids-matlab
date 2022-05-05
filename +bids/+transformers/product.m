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
  % (C) Copyright 2022 Remi Gau

  inputs = bids.transformers.get_input(transformer, data);
  outputs = bids.transformers.get_output(transformer, data);

  assert(numel(outputs) == 1);

  outputs = outputs{1};

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

    tmp(:, i) = data.(inputs{i});

  end

  if omit_nan
    data.(outputs) = prod(tmp, 2, 'omitnan');

  else
    data.(outputs) = prod(tmp, 2);

  end

end
