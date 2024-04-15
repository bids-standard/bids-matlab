function data = Rename(transformer, data)
  %
  %   Rename a variable.
  %
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
