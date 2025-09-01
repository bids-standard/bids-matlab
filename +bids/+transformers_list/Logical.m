function data = Logical(transformer, data)
  %
  % Each of these transformations:
  %
  % - takes 2 or more columns as input
  % -  performs the corresponding logical operation
  %
  %   - inclusive or
  %   - conjunction
  %   - logical negation
  %
  % - returning a single column as output.
  %
  %
  % If non-logical input are passed, it is expected that:
  %
  % - all zero or nan (for numeric data types),
  % - "NaN" or empty (for char) values
  %
  % will evaluate to false and all other values will evaluate to true.
  %
  % Arguments:
  %
  % :param Name: **mandatory**.  Any of ``And``, ``Or``, ``Not``.
  % :type  Input: char
  %
  % :param Input: **mandatory**.  An array of columns to perform operation on. Only 1 for ``Not``
  % :type  Input: array
  %
  % :param Output: Optional. The name of the output column.
  % :type  Output: char or array
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  % TODO
  % for Add Or, if not output just merge the name of the input variables
  % TODO "not" can only have one input

  input = bids.transformers_list.get_input(transformer, data);

  output = bids.transformers_list.get_output(transformer, data);
  assert(isscalar(output));

  % try coerce all input to logical
  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    if iscell(data.(input{i}))
      tmp1 = ~cellfun('isempty', data.(input{i}));
      tmp2 = ~cellfun(@(x) all(isnan(x)), data.(input{i}));
      tmp(:, i) = all([tmp1 tmp2], 2);

    else
      tmp2 = data.(input{i});
      tmp2(isnan(tmp2)) = 0;
      tmp(:, i) = logical(tmp2);

    end

  end

  switch lower(transformer.Name)
    case 'and'
      data.(output{1}) = all(tmp, 2);
    case 'or'
      data.(output{1}) = any(tmp, 2);
    case 'not'

      data.(output{1}) = ~tmp;
  end

end
