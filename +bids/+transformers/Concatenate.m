function data = Concatenate(transformer, data)
  %
  % Concatnate columns together.
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
  % :param Input: **mandatory**. TODO
  % :type  Input: array
  %
  % :param Output: optional. TODO
  % :type  Output: string or array
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

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data, false);

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
