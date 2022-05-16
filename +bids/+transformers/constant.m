function data = constant(transformer, data)
  %
  % Adds a new column with a constant value.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %       {
  %         "Name":  "Constant",
  %         "Value": 1,
  %         "Output": "intercept"
  %       }
  %
  %
  % Arguments:
  %
  % :param Output: **mandatory**. Name of the newly generated column.
  % :type  Output: string or array
  %
  % :param Input: optional. The value of the constant, defaults to ``1``.
  % :type  Input: float
  %
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Constant', ...
  %                         'Value', 1, ...
  %                         'Ouput', 'intercept');
  %
  %
  %   data = bids.transformers.constant(transformer, data);
  %
  %
  %   ans =
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  output = bids.transformers.get_output(transformer, data);

  assert(numel(output) == 1);

  value = 1;
  if isfield(transformer, 'Value')
    value = transformer.Value;
  end

  data.(output{1}) = ones(size(data.onset)) * value;
end
