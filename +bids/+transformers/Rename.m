function data = Rename(transformer, data)
  %
  %   Rename a variable.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "Rename",
  %       "Input": [
  %           "age_gt_70",
  %           "age_lt_18",
  %       ],
  %       "Output": [
  %           "senior",
  %           "teenager",
  %       ]
  %     }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name(s) of the variable(s) to rename.
  % :type  Input: string or array
  %
  % :param Output: optional. New column names to output.
  %                          Must match length of input column(s),
  %                          and columns will be mapped 1-to-1 in order.
  % :type  Output: string or array
  %
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Rename', ...
  %                         'Input', {{'age_gt_70', 'age_lt_18'}}, ...
  %                         'Ouput', {{'senior', 'teenager'}});
  %
  %   data. = ;
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.
  %
  %   ans =
  %
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  assert(numel(input) == numel(output));

  for i = 1:numel(input)
    data.(output{i}) = data.(input{i});
    data = rmfield(data, input{i});
  end

end
