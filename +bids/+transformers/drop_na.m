function data = drop_na(transformer, data)
  %
  % Drops all rows with "n/a".
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "Drop_na",
  %       "Input": [
  %           "age_gt_twenty"
  %       ],
  %       "Output": [
  %           "age_gt_twenty_clean"
  %       ]
  %     }
  %
  % Arguments:
  %
  % :param Input: **mandatory**.  The name of the variable to operate on.
  % :type  Input: array
  %
  % :param Output: optional. The list of column names to write out to.
  %                          By default, computation is done in-place
  %                          meaning that input columnise overwritten).
  % :type  Output: array
  %
  % **CODE EXAMPLE**::
  %
  %   TODO
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

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
