function data = Rename(transformer, data)
  %
  %   Rename a variable.
  %
  % JSON EXAMPLE
  % ------------
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
  % Arguments:
  %
  % :param Input: **mandatory**. The name(s) of the variable(s) to rename.
  % :type  Input: string or array
  %
  % :param Output: Optional. New column names to output.
  %                          Must match length of input column(s),
  %                          and columns will be mapped 1-to-1 in order.
  % :type  Output: string or array
  %
  % CODE EXAMPLE
  % ------------
  %
  % .. code-block:: matlab
  %
  %   transformer = struct('Name', 'Rename', ...
  %                         'Input', {{'age_gt_70', 'age_lt_18'}}, ...
  %                         'Ouput', {{'senior', 'teenager'}});
  %
  %   data.age_gt_70 = 75;
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data. TODO
  %
  %   ans = TODO
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data);

  assert(numel(input) == numel(output));

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    data.(output{i}) = data.(input{i});
    data = rmfield(data, input{i});
  end

end
