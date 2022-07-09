function new_data = Merge_identical_rows(transformer, data)
  %
  % MErge consecutive identical rows
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "MergeIdenticalRows",
  %       "Input": "trial_type",
  %     }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name(s) of the variable(s) to operate on.
  % :type  Input: string or array
  %
  %
  % **CODE EXAMPLE**::
  %
  %
  %
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  fields = fieldnames(data);

  if all(ismember(fields, {'onset', 'duration'}))
    error('input data must have onset and duration fields.');
  end

  % sort data by onset
  [~, idx] = sort(data.onset);
  for i_field = 1:numel(fields)
    data.(fields{i_field}) = data.(fields{i_field})(idx);
  end

  input = bids.transformers_list.get_input(transformer, data);

  new_data = struct();
  row = 1;

  for i = 1:numel(input)

    previous_value = data.(input{i})(1);
    if iscell(previous_value)
      previous_value = previous_value{1};
    end
    onset = data.onset(1);

    for j = 2:numel(data.(input{i}))

      is_same = false;

      this_value = data.(input{i})(j);
      if iscell(this_value)
        this_value = this_value{1};
      end

      if all(isnumeric([this_value, previous_value])) && this_value == previous_value
        is_same = true;
      elseif all(ischar([this_value, previous_value])) && strcmp(this_value, previous_value)
        is_same = true;
      end

      if ~is_same

        for i_field = 1:numel(fields)
          new_data.(fields{i_field})(row, 1) = data.(fields{i_field})(j - 1);
        end
        new_data.onset(row, 1) = onset;
        new_data.duration(row, 1) =  data.onset(j - 1) + data.duration(j - 1) - onset;

        row = row + 1;

        onset = data.onset(j);
      end

      previous_value = this_value;

    end

    % for the last row
    for i_field = 1:numel(fields)
      new_data.(fields{i_field})(row, 1) = data.(fields{i_field})(j);
    end
    new_data.duration(row, 1) =  data.onset(j) + data.duration(j) - onset;
    new_data.onset(row, 1) = onset;

  end

end
