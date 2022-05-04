function data = logical(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);

  % TODO output can only be numel==1
  outputs = bids.transformers.get_output(transformer);

  % try coerce all inputs to logical
  for i = 1:numel(inputs)

    if ~isfield(data, inputs{i})
      % TODO throw warning
      return
    end

    if iscellstr(data.(inputs{i}))
      tmp(:, i) = cellfun('isempty', data.(inputs{i}));

    else
      tmp2 = data.(inputs{i});
      tmp2(isnan(tmp2)) = 0;
      tmp(:, i) = logical(tmp2);

    end

  end

  switch lower(transformer.Name)
    case 'and'
      data.(outputs{1}) = all(tmp, 2);
    case 'or'
      data.(outputs{1}) = any(tmp, 2);
    case 'not'
      % TODO "not" can only have one input
      data.(outputs{1}) = ~tmp;
  end

end
