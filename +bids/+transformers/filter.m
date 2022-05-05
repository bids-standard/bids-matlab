function data = filter(transformer, data)
  %
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
