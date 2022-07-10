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
  % :param Output: optional. Name of the output column.
  % :type  Output: string
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Concatenate', ...
  %                         'Input', {{'face_type', 'face_repetition'}}, ...
  %                         'Ouput', 'face_type_repetition');
  %
  %   data.face_type = ;
  %   data.face_repetition = ;
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.
  %
  %   ans =
  %
  %
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data, false);

  % TODO: remove assumption that this is an event.tsv file
  % and that we can rely on a onset column being present
  for row = 1:numel(data.onset)

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
