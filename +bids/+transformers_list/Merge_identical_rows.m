function new_data = Merge_identical_rows(transformer, data)
  %
  % Merge consecutive identical rows
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
