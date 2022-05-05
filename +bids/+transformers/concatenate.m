function data = concatenate(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau
  inputs = bids.transformers.get_input(transformer, data);
  outputs = bids.transformers.get_output(transformer, data);

  for row = 1:numel(data.onset)
    tmp1 = {};
    for i = 1:numel(inputs)

      if isnumeric(data.(inputs{i}))
        tmp1{1, i} = num2str(data.(inputs{i})(row));
      elseif iscellstr(data.(inputs{i}))
        tmp1{1, i} = data.(inputs{i}){row};
      end
    end
    tmp2{row, 1} = strjoin(tmp1, '_');
  end

  data.(outputs{1}) = tmp2;

end
