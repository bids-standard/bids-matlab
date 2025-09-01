function data = Concatenate(transformer, data)
  %
  % Concatenate columns together.
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. Column(s) to concatenate. Must all be of the same length.
  % :type  Input: array
  %
  % :param Output: Optional. Name of the output column.
  % :type  Output: char
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  if any(~ismember(input, fieldnames(data)))
    return
  end
  output = bids.transformers_list.get_output(transformer, data, false);

  nb_rows = [];
  for i = 1:numel(input)
    nb_rows(i) = size(data.(input{i}), 1); %#ok<AGROW>
  end
  nb_rows = unique(nb_rows);
  assert(isscalar(nb_rows));

  for row = 1:nb_rows

    tmp1 = {};

    for i = 1:numel(input)

      if isnumeric(data.(input{i}))
        tmp1{1, i} = num2str(data.(input{i})(row));

      elseif iscellstr(data.(input{i}))
        tmp1{1, i} = data.(input{i}){row};

      elseif iscell(data.(input{i}))
        tmp1{1, i} = data.(input{i}){row};

        if isnumeric(tmp1{1, i})
          tmp1{1, i} = num2str(tmp1{1, i});
        end

      end

    end

    tmp2{row, 1} = strjoin(tmp1, '_');

  end

  data.(output{1}) = tmp2;

end
