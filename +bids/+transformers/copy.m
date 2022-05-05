function data = copy(transformer, data)
  %
  %
  %
  % Clones/copies each of the input columns to a new column with identical values
  % and a different name. Useful as a basis for subsequent transformations that need
  % to modify their inputs in-place.
  % Arguments:
  %
  % - Input (list; mandatory): A list of column names to copy.
  % - Output (list; mandatory): A list of the names to copy the input columns to.
  %                             Must be same length as input, and columns are mapped one-to-one
  %                             from the input list to the output list.
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);
  outputs = bids.transformers.get_output(transformer);

  assert(numel(inputs) == numel(outputs));

  for i = 1:numel(inputs)
    data.(outputs{i}) = data.(inputs{i});
  end

end
