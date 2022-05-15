function data = delete(transformer, data)
  %
  % USAGE::
  %
  %   data = delete(transformer, data)
  %
  % Deletes column(s) from further analysis.
  %
  % Arguments:
  %
  % - Input (array; mandatory): The name(s) of the columns(s) to delete.
  %
  % Notes: The ``Select`` transformation provides the inverse function
  % (selection of columns to keep for subsequent analysis).
  %
  % (C) Copyright 2022 Remi Gau

  input = bids.transformers.get_input(transformer, data);

  for i = 1:numel(input)
    data = rmfield(data, input{i});
  end

end
