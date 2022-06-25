function data = Basic(transformer, data)
  %
  % Perfoms a basic operation with a ``Value`` on the ``Input``
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %       {
  %         "Name":  "Add",
  %         "Input": "onset",
  %         "Value": 0.5,
  %         "Output": "delayed_onset"
  %         "Query": "familiarity == Famous face"
  %       }
  %
  % Each of these transformations takes one or more columns,
  % and performs a mathematical operation on the input column and a provided operand.
  % The operations are performed on each column independently.
  %
  %
  % Arguments:
  %
  % :param Name: **mandatory**.  Any of ``Add``, ``Subtract``, ``Multiply``, ``Divide``, ``Power``.
  % :type  Input: string
  %
  % :param Input: **mandatory**.  A array of columns to perform operation on.
  % :type  Input: string or array
  %
  % :param Value: **mandatory**.  The value to perform operation with (i.e. operand).
  % :type  Value: float
  %
  % :param Query: optional. Boolean expression used to select on which rows to
  %               act.
  % :type  Query: string
  %
  % :param Output: optional. List of column names to write out to.
  % :type  Output: string or array
  %
  % By default, computation is done in-place on the input
  % (meaning that input columns are overwritten).
  % If provided, the number of values must exactly match the number of input values,
  % and the order will be mapped 1-to-1.
  %
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Subtract', ...
  %                         'Input', 'onset', ...
  %                         'Value', 3, ...
  %                         'Ouput', 'onset_minus_3');
  %
  %   data.onset = [1; 2; 5; 6];
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.onset_minus_3
  %
  %   ans =
  %
  %         -2
  %         -1
  %          2
  %          3
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  rows = true(size(data.(input{1})));

  [left, query_type, right] = bids.transformers.get_query(transformer);
  if ~isempty(query_type)

    bids.transformers.check_field(left, data, 'query', false);

    rows = bids.transformers.identify_rows(data, left, query_type, right);

  end

  for i = 1:numel(input)

    value = transformer.Value;

    if ischar(value)
      value = str2double(value);
      if isnan(value)
        msg = sprintf('basic transformers require values convertable to numeric. Got: %s', ...
                      transformer.Value);
        bids.internal.error_handling(mfilename(), ...
                                     'numericOrCoercableToNumericRequired', ...
                                     msg, ...
                                     false);
      end
    end

    assert(isnumeric(value));

    switch lower(transformer.Name)

      case 'add'
        tmp = data.(input{i}) + value;

      case 'subtract'
        tmp = data.(input{i}) - value;

      case 'multiply'
        tmp = data.(input{i}) * value;

      case 'divide'
        tmp = data.(input{i}) / value;

      case 'power'
        tmp = data.(input{i}).^value;

    end

    data.(output{i})(rows, :) = tmp(rows, :);

  end

end
