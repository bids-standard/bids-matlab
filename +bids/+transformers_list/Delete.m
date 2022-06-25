function data = Delete(transformer, data)
  %
  % Deletes column(s) from further analysis.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "Delete",
  %       "Input": [
  %           "sex_m",
  %           "age_gt_twenty"
  %       ]
  %     }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name(s) of the columns(s) to delete.
  % :type  Input: string or array
  %
  %
  % .. note::
  %
  %   The ``Select`` transformation provides the inverse function
  %   (selection of columns to keep for subsequent analysis).
  %
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Delete', ...
  %                         'Input', {{'sex_m', age_gt_twenty}});
  %
  %   data.sex_m = ;
  %   data.age_gt_twenty = ;
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.
  %
  %   ans =
  %
  %
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);

  for i = 1:numel(input)
    data = rmfield(data, input{i});
  end

end
