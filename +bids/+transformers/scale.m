function data = scale(transformer, data)
  %
  %
  % Scales the values of one or more columns.
  % Semantics mimic scikit-learn, such that demeaning and
  % rescaling are treated as independent arguments,
  % with the default being to apply both
  % (i.e., standardizing each value so that it has zero mean and unit SD).
  %
  % Arguments:
  %
  % Input(list, mandatory): Names of columns to standardize.
  %
  % Demean(bool, optional): If True, subtracts the mean from each input column
  % (i.e., applies mean-centering).
  %
  % Rescale(bool, optional): If True, divides each column by its standard deviation.
  %
  % ReplaceNa(string, optional). Whether/when to replace missing values with 0.
  % If None, no replacement is performed.
  % If 'before', missing values are replaced with 0's before scaling.
  % If 'after', missing values are replaced with 0 after scaling.
  %
  % Output(list, optional): Optional names of columns to output.
  % Must match length of input column if provided, and columns will be mapped 1-to-1 in order.
  % If no output values are provided,
  % the scaling transformation is applied in-place to all the inputs.
  %
  %
  %
  % (C) Copyright 2022 Remi Gau

  inputs = bids.transformers.get_input(transformer, data);
  outputs = bids.transformers.get_output(transformer, data);

  demean = true;
  if isfield(transformer, 'Demean')
    demean = transformer.Demean;
  end

  rescale = true;
  if isfield(transformer, 'Rescale')
    rescale = transformer.Rescale;
  end

  replace_na = 'off';
  if isfield(transformer, 'ReplaceNa')
    replace_na = transformer.ReplaceNa;
  end

  for i = 1:numel(inputs)

    this_input = data.(inputs{i});

    if ~isnumeric(this_input)
      error('non numeric variable: %s', inputs{i});
    end

    nan_values = isnan(this_input);

    if numel(unique(this_input)) == 1 && ismember(replace_na, {'off', 'before'})
      error(['Cannot scale a column with constant value %s\n', ...
             'If you want a constant column of 0 returned,\n'
             'set "replace_na" to "after"'], unique(this_input));
    end

    if strcmp(replace_na, 'before')
      this_input(nan_values) = zeros(sum(nan_values));
    end

    if demean
      this_input = this_input - mean(this_input, 'omitnan');
    end

    if rescale
      this_input = this_input / std(this_input, 'omitnan');
    end

    if strcmp(replace_na, 'after')
      this_input(nan_values) = zeros(sum(nan_values));
    end

    data.(outputs{i}) = this_input;

  end

end
