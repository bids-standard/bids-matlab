function data = filter(transformer, data)
  %
  %
  % Subsets rows using a boolean expression.
  %
  % Arguments:
  %
  % - Input(list; mandatory): The name(s) of the variable(s) to operate on.
  % - Query(str; mandatory): Boolean expression used to filter
  % - Output (list; optional): the optional list of column names to write out to.
  %
  % By default, computation is done in-place (i.e., input columnise overwritten).
  % If provided, the number of values must exactly match the number of input values,
  % and the order will be mapped 1-to-1.
  %
  % (C) Copyright 2022 Remi Gau

  % TODO
  % - By(str; optional): Name of column to group filter operation by

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  [left, query_type, right] = bids.transformers.get_query(transformer);
  bids.transformers.check_field(left, data, 'query', false);

  % identify rows
  if iscellstr(data.(left))

    if ismember(query_type, {'>', '<', '>=', '<='})
      msg = sprtinf(['Types "%s" are not supported for queries on string\n'...
                     'in query %s'], ...
                    {'>, <, >=, <='}, ...
                    query);
      bids.internal.error_handling(mfilename(), ...
                                   'unsupportedQueryType', ...
                                   msg, ...
                                   false);

    end

    idx = strcmp(data.(left), right);

  elseif isnumeric(data.(left))

    right = str2num(right);

    switch query_type

      case '=='
        idx = data.(left) == right;

      case '>'
        idx = data.(left) > right;

      case '<'
        idx = data.(left) < right;

      case '>='
        idx = data.(left) >= right;

      case '<='
        idx = data.(left) <= right;

    end

  end

  % filter rows of all inputs
  for i = 1:numel(input)

    clear tmp;

    if iscellstr(data.(input{i}))

      tmp(idx, 1) = data.(input{i})(idx);

      tmp(~idx, 1) = repmat({nan}, sum(~idx), 1);

    elseif isnumeric(data.(input{i}))

      tmp(idx, 1) = data.(left)(idx);

      if iscellstr(tmp)
        tmp(~idx, 1) = repmat({nan}, sum(~idx), 1);
      else
        tmp(~idx, 1) = nan;
      end

    end

    data.(output{i}) = tmp;

  end

end
