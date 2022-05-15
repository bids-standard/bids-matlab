function data = concatenate(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau
  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  for row = 1:numel(data.onset)

    tmp1 = {};

    for i = 1:numel(input)
      if isnumeric(data.(input{i}))
        tmp1{1, i} = num2str(data.(input{i})(row));
      elseif iscellstr(data.(input{i}))
        tmp1{1, i} = data.(input{i}){row};
      end
    end

    tmp2{row, 1} = strjoin(tmp1, '_');

  end

  data.(output{1}) = tmp2;

end
