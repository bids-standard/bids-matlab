function data = Concatenate(transformer, data)
  %
  % Concatenate columns together.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "Concatenate",
  %       "Input": [
  %           "face_type",
  %           "face_repetition"
  %       ],
  %       "Output": "face_type_repetition"
  %     }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. Column(s) to concatenate. Must all be of the same length.
  % :type  Input: array
  %
  % :param Output: Optional. Name of the output column.
  % :type  Output: string
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Concatenate', ...
  %                         'Input', {{'face_type', 'face_repetition'}}, ...
  %                         'Ouput', 'face_type_repetition');
  %
  %   data.face_type = {'familiar'; 'unknwown'; 'new'; 'familiar'; 'unknwown'; 'new'};
  %   data.face_repetition = [1;1;1;2;2;2];
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.face_type_repetition
  %
  %   ans =
  %      {
  %        'familiar_1'
  %        'unknwown_1'
  %        'new_1'
  %        'familiar_2'
  %        'unknwown_2'
  %        'new_2'
  %      }
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
  assert(length(nb_rows) == 1);

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
