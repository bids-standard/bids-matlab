function new_data = Merge_identical_rows(transformer, data)
  %
  % Merge consecutive identical rows.
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
  % :type  Input: char or array
  %
  % .. note::
  %
  %    - Only works on data commit from event.tsv
  %    - Content is sorted by onset time before merging
  %    - If multiple variables are specified, they are merged in the order they are specified
  %    - If a variable is not found, it is ignored
  %    - If a variable is found, but is empty, it is ignored
  %    - The content of the other columns corresponds to the last row being merged:
  %      this means that the content from other columns but the one specified in will be deleted
  %      execpt for the last one
  %
  % **CODE EXAMPLE**::
  %
  %    transformers(1).Name = 'MergeIdenticalRows';
  %    transformers(1).Input = {'trial_type'};
  %
  %    data.trial_type = {'house' ; 'face'  ; 'face'; 'house'; 'chair'; 'house' ; 'chair'};
  %    data.duration =   [1       ; 1       ; 1     ; 1      ; 1      ; 1       ; 1];
  %    data.onset =      [3       ; 1       ; 2     ; 6      ; 8      ; 4       ; 7];
  %    data.stim_type =  {'delete'; 'delete'; 'keep'; 'keep' ; 'keep' ; 'delete'; 'delete'};
  %
  %    new_content = bids.transformers(transformers, data);
  %
  %    new_content.trial_type
  %    ans =
  %      3X1 cell array
  %        'face'
  %        'house'
  %        'chair'
  %
  %    new_content.stim_type
  %    ans =
  %      3X1 cell array
  %        'keep'
  %        'keep'
  %        'keep'
  %
  %    new_content.onset
  %    ans =
  %         1
  %         3
  %         7
  %
  %    new_content.duration
  %    ans =
  %         2
  %         4
  %         2
  %
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  % TODO: tests to see if works on columns with mixed content (cell of numbers and char)
  % TODO: merge only if cell content matches some condition

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

  % create a new structure add a new row every time we encounter a new row
  % with a different content (for the input of interest) from the previous one.
  %
  new_data = struct();
  row = 1;

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    % start with values from the first row and start loop at row 2
    previous_value = data.(input{i})(1);
    if iscell(previous_value)
      previous_value = previous_value{1};
    end

    onset = data.onset(1);

    for j = 2:numel(data.(input{i}))

      this_value = data.(input{i})(j);
      if iscell(this_value)
        this_value = this_value{1};
      end

      is_same = compare_rows(this_value, previous_value);

      if ~is_same

        [new_data, row] = add_row(data, new_data, onset, row, j - 1);

        onset = data.onset(j);

      end

      previous_value = this_value;

    end

    % for the last row
    new_data = add_row(data, new_data, onset, row, j);

  end

end

function is_same = compare_rows(this_value, previous_value)

  is_same = false;

  if isempty(previous_value)
  elseif all(isnumeric([this_value, previous_value])) && this_value == previous_value
    is_same = true;
  elseif all(ischar([this_value, previous_value])) && strcmp(this_value, previous_value)
    is_same = true;
  end

end

function [new_data, new_data_row] = add_row(data, new_data, onset, new_data_row, data_row)

  fields = fieldnames(data);

  for i_field = 1:numel(fields)
    new_data.(fields{i_field})(new_data_row, 1) = data.(fields{i_field})(data_row);
  end
  new_data.onset(new_data_row, 1) = onset;
  new_data.duration(new_data_row, 1) =  data.onset(data_row) + data.duration(data_row) - onset;

  new_data_row = new_data_row + 1;

end
