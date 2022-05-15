function data = select(transformer, data)
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  % The select transformation specifies which columns to retain for subsequent analysis.
  % Any columns that are not specified here will be dropped.
  % Arguments:
  % Input (list,  mandatory): The names of all columns to keep.
  % Any columns not in this list will be deleted and
  % will not be available to any subsequent transformations or downstream analyses.
  % Notes: one can think of select as the inverse the Delete transformation
  % that removes all named columns from further analysis.

  input = bids.transformers.get_input(transformer, data);

  for i = 1:numel(input)
    tmp.(input{i}) = data.(input{i});
  end

  data = tmp;
end
