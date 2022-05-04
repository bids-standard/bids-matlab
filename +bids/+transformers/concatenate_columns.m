function tsv_content = concatenate_columns(transformer, tsv_content)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer);
  outputs = bids.transformers.get_output(transformer);

  for row = 1:numel(tsv_content.onset)
    tmp1 = {};
    for i = 1:numel(inputs)
      if isnumeric(tsv_content.(inputs{i}))
        tmp1{1, i} = num2str(tsv_content.(inputs{i})(row));
      elseif iscellstr(tsv_content.(inputs{i}))
        tmp1{1, i} = tsv_content.(inputs{i}){row};
      end
    end
    tmp2{row, 1} = strjoin(tmp1, '_');
  end

  tsv_content.(outputs{1}) = tmp2;

end
