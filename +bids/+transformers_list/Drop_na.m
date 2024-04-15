function data = Drop_na(transformer, data)
  %
  % Drops all rows with "n/a".
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**.  The name of the variable to operate on.
  % :type  Input: char or array
  %
  % :param Output: Optional. The column names to write out to.
  %                          By default, computation is done in-place
  %                          meaning that input columnise overwritten).
  % :type  Output: char or array
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data);

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

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
