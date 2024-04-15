function data = Basic(transformer, data)
  %
  % Performs a basic operation with a ``Value`` on the ``Input``
  %
  %
  % Each of these transformations takes one or more columns,
  % and performs a mathematical operation on the input column and a provided operand.
  % The operations are performed on each column independently.
  %
  % Arguments:
  %
  % :param Name: **mandatory**.  Any of ``Add``, ``Subtract``, ``Multiply``, ``Divide``, ``Power``.
  % :type  Input: char
  %
  % :param Input: **mandatory**.  A array of columns to perform operation on.
  % :type  Input: char or array
  %
  % :param Value: **mandatory**.  The value to perform operation with (i.e. operand).
  % :type  Value: float
  %
  % :param Query: Optional. logical expression used to select on which rows to
  %               act.
  % :type  Query: char
  %
  % :param Output: Optional. List of column names to write out to.
  % :type  Output: char or array
  %
  % By default, computation is done in-place on the input
  % (meaning that input columns are overwritten).
  % If provided, the number of values must exactly match the number of input values,
  % and the order will be mapped 1-to-1.
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data);

  rows = true(size(data.(input{1})));

  [left, query_type, right] = bids.transformers_list.get_query(transformer);
  if ~isempty(query_type)

    % if the variable to run query on does not exist we return
    status = bids.transformers_list.check_field(left, data, 'query', true);
    if ~status
      return
    end

    rows = bids.transformers_list.identify_rows(data, left, query_type, right);

  end

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    value = transformer.Value;

    if ischar(value)
      value = str2double(value);
      if isnan(value)
        msg = sprintf('basic transformers require values convertible to numeric. Got: %s', ...
                      transformer.Value);
        bids.internal.error_handling(mfilename(), ...
                                     'numericOrCoercableToNumericRequired', ...
                                     msg, ...
                                     false);
      end
    end

    assert(isnumeric(value));

    tmp = data.(input{i});
    if iscellstr(tmp) %#ok<ISCLSTR>
      tmp = str2num(char(tmp)); %#ok<ST2NM>
    end

    switch lower(transformer.Name)

      case 'add'
        tmp = tmp + value;

      case 'subtract'
        tmp = tmp - value;

      case 'multiply'
        tmp = tmp * value;

      case 'divide'
        tmp = tmp / value;

      case 'power'
        tmp = tmp.^value;

    end

    data.(output{i})(rows, :) = tmp(rows, :);

  end

end
