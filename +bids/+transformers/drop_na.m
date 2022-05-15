function data = drop_na(transformer, data)
  %
  %
  %
  % Drops all rows with "n/a".
  %
  % Arguments:
  %
  % Input(string; mandatory): The name of the variable to operate on.
  % Output (string; optional): the optional list of column names to write out to.
  % By default, computation is done in-place (i.e., input columnise overwritten).
  %
  %
  %
  %
  % (C) Copyright 2022 Remi Gau

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  for i = 1:numel(input)

    this_input = data.(input{i});

    if isnumeric(this_input)
      nan_values = isnan(this_input);
    elseif iscell(this_input)
      nan_values = cellfun(@(x) all(isnan(x)), this_input);
    end

    this_input(nan_values) = [];

    data.(output{i}) = this_input;

  end

end
