function data = filter(transformer, data)
  %
  %
  % Subsets rows using a boolean expression.
  %
  % Arguments:
  %
  % - Input(list; mandatory): The name(s) of the variable(s) to operate on.
  % - Query(str; mandatory): Boolean expression used to filter
  % - By(str; optional): Name of column to group filter operation by
  % - Output (list; optional): the optional list of column names to write out to.
  %
  % By default, computation is done in-place (i.e., input columnise overwritten).
  % If provided, the number of values must exactly match the number of input values,
  % and the order will be mapped 1-to-1.
  %
  % (C) Copyright 2022 Remi Gau

  inputs = bids.transformers.get_input(transformer, data);
  outputs = bids.transformers.get_output(transformer, data);

  if isfield(transformer, 'By')
    % TODO
    by = transformer.By;
  end

  for i = 1:numel(inputs)

    tokens = regexp(inputs{i}, '\.', 'split');

    query = transformer.Query;
    if isempty(regexp(query, tokens{1}, 'ONCE'))
      return
    end

    queryTokens = regexp(query, '==', 'split');
    if numel(queryTokens) > 1

      if iscellstr(data.(tokens{1}))
        idx = strcmp(queryTokens{2}, data.(tokens{1}));
        tmp(idx, 1) = data.(tokens{1})(idx);
        tmp(~idx, 1) = repmat({''}, sum(~idx), 1);
      end

      if isnumeric(data.(tokens{1}))
        idx = data.(tokens{1}) == str2num(queryTokens{2});
        tmp(idx, 1) = data.(tokens{1})(idx);
        tmp(~idx, 1) = nan;
      end

      tmp(idx, 1) = data.(tokens{1})(idx);
      data.(outputs{i}) = tmp;

    end

  end

end
