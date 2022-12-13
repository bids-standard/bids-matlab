function data = Filter(transformer, data)
  %
  % Subsets rows using a logical expression.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "Filter",
  %       "Input": "sex",
  %       "Query": "age > 20"
  %     }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name(s) of the variable(s) to operate on.
  % :type  Input: string or array
  %
  % :param Query: **mandatory**. logical expression used to filter
  % :type  Query: string
  %
  % Supports:
  %
  %   - ``>``, ``<``, ``>=``, ``<=``, ``==``, ``~=`` for numeric values
  %
  %   - ``==``, ``~=`` for string operation (case sensitive).
  %     Regular expressions are supported
  %
  % :param Output: Optional. The optional column names to write out to.
  % :type  Output: string or array
  %
  % By default, computation is done in-place (i.e., input columnise overwritten).
  % If provided, the number of values must exactly match the number of input values,
  % and the order will be mapped 1-to-1.
  %
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Filter', ...
  %                         'Input', 'sex', ...
  %                         'Query', 'age > 20');
  %
  %   data.sex = {'M', 'F', 'F', 'M'};
  %   data.age = [10, 21, 15, 26];
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.sex
  %
  %     ans =
  %
  %     4X1 cell array
  %
  %         [NaN]
  %         'F'
  %         [NaN]
  %         'M'
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  % TODO
  % - By(str; optional): Name of column to group filter operation by

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data);

  [left, query_type, right] = bids.transformers_list.get_query(transformer);
  bids.transformers_list.check_field(left, data, 'query', false);

  rows = bids.transformers_list.identify_rows(data, left, query_type, right);

  % filter rows of all inputs
  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    clear tmp;

    tmp(rows, 1) = data.(input{i})(rows);

    if iscell(tmp)
      tmp(~rows, 1) = repmat({nan}, sum(~rows), 1);
    else
      tmp(~rows, 1) = nan;
    end

    data.(output{i}) = tmp;

  end

end
