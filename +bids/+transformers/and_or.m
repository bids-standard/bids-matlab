function tsv_content = and_or(transformer, tsv_content)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);
  outputs = bids.transformers.get_output(transformer);

  for i = 1:numel(inputs)

    if ~isfield(tsv_content, inputs{i})
      return
    end

    if iscellstr(tsv_content.(inputs{i}))
      tmp(:, i) = cellfun('isempty', tsv_content.(inputs{i}));

    else
      tmp2 = tsv_content.(inputs{i});
      tmp2(isnan(tmp2)) = 0;
      tmp(:, i) = logical(tmp2);

    end

  end

  switch lower(transformer.Name)
    case 'and'
      tsv_content.(outputs{1}) = all(tmp, 2);
    case 'or'
      tsv_content.(outputs{1}) = any(tmp, 2);
  end

end
