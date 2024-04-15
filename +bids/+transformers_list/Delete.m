function data = Delete(transformer, data)
  %
  % Deletes column(s) from further analysis.
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name(s) of the columns(s) to delete.
  % :type  Input: char or array
  %
  % .. note::
  %
  %   The ``Select`` transformation provides the inverse function
  %   (selection of columns to keep for subsequent analysis).
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    data = rmfield(data, input{i});
  end

end
