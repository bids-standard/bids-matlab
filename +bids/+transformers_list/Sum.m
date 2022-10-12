function data = Sum(transformer, data)
  %
  % Computes the (optionally weighted) row-wise sums of two or more columns.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %       {
  %         "Name":  "Sum",
  %         "Input": ["duration", "reaction_time"],
  %         "Output": "duration_X_reaction_time",
  %         "Weights": [1, 0.5],
  %         "OmitNan": false,
  %       }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. Names of two or more columns to sum.
  % :type  Input: array
  %
  % :param Output: **mandatory**. Name of the newly generated column.
  % :type  Output: string or array
  %
  % :param OmitNan: optional. If ``false`` any column with nan values will return a nan value.
  %                           If ``true`` nan values are skipped. Defaults to ``false``.
  % :type  OmitNan: boolean
  %
  % :param Weights: optional. Optional array of floats giving the weights of the columns.
  %                           If provided, length of weights must equal
  %                           to the number of values in input,
  %                           and weights will be mapped 1-to-1 onto named columns.
  %                           If no weights are provided,
  %                           defaults to unit weights (i.e., simple sum).
  % :type  Weights: array
  %
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Sum', ...
  %                         'Input',  {{'duration', 'reaction_time'}}, ...
  %                         'OmitNan', false, ...
  %                         'Weights': [1, 0.5], ...
  %                         'Ouput', 'duration_plus_reaction_time');
  %
  %   data.duration =
  %   data.reaction_time =
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.duration_plus_reaction_time =
  %
  %   ans =
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data);

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
