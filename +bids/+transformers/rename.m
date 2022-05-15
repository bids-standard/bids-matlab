function data = rename(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau

  %   Rename a variable.
  % Arguments:
  % Input(list, mandatory): The name(s) of the variable(s) to rename.
  % Output (list, mandatory): New column names to output.
  % Must match length of input column(s), and columns will be mapped 1-to-1 in order.

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  assert(numel(input) == numel(output));

  for i = 1:numel(input)
    data.(output{i}) = data.(input{i});
    data = rmfield(data, input{i});
  end

end
