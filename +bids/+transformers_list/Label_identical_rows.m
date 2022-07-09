function data = Label_identical_rows(transformer, data)
  %
  % Creates an extra column to index consecutive identical rows in a column.
  % The index restarts at 1 with every change of row content.
  % This can for example be used to label consecutive events of the same trial_type in
  % a block.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "LabelIdenticalRows",
  %       "Input": "trial_type",
  %       "Cumulative": False
  %     }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name(s) of the variable(s) to operate on.
  % :type  Input: string or array
  %
  % :param Cumulative: **optional**. Defaults to ``False``.
  %                    If ``True``, the labels are not reset to 0
  %                    when encoutering new row content.
  % :type  Cumulative: boolean
  %
  % .. note::
  %
  %     The labels will be by default be put in a column called Input(i)_label
  %
  % **CODE EXAMPLE**::
  %
  %
  %   transformers(1).Name = 'LabelIdenticalRows';
  %   transformers(1).Input = {'trial_type', 'stim_type'};
  %
  %   data.trial_type = {'face';'face';'house';'house';'house';'house';'chair'};
  %   data.stim_type =  {1'    ; 1    ;1      ;2      ;5      ;2      ; nan};
  %
  %   new_content = bids.transformers(transformers, data);
  %
  %   assertEqual(new_content.trial_type_label, [1;2;1;2;3;4;1]);
  %   assertEqual(new_content.stim_type_label,  [1;2;3;1;1;1;1]);
  %
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data);

  cumulative = false;
  if isfield(transformer, 'Cumulative')
    cumulative = transformer.Cumulative;
  end

  for i = 1:numel(input)

    if strcmp(output{i}, input{i})
      output{i} = [output{i} '_label'];
    end

    if isfield(data, output{i})
      bids.internal.error_handling(mfilename(), ...
                                   'outputFieldAlreadyExist', ...
                                   sprintf('The output field already "%s" exists', output{i}), ...
                                   false);
    end

    % TODO: does not cover the edge case where data.(input{i}) has one row
    % with non numeric content
    if cumulative
      label_counter = unique(data.(input{i}));
      if ~iscell(label_counter)
        label_counter = num2cell(label_counter);
      end
      label_counter = reset_label_counter(label_counter);
    else
      label_counter = 1;
    end

    previous_value = [];

    for j = 1:numel(data.(input{i}))

      this_value = data.(input{i})(j);
      if iscell(this_value)
        this_value = this_value{1};
      end

      is_same = compare_rows(this_value, previous_value);

      if cumulative
        if isnumeric(this_value)
          idx = cellfun(@(x) isnumeric(x) && x == this_value, label_counter);
        elseif ischar(this_value)
          idx = cellfun(@(x) ischar(x) && strcmp(x, this_value), label_counter);
        end
        idx = find(idx);
        label_counter{idx, 2} = label_counter{idx, 2} + 1;
      end

      if is_same && ~cumulative
        label_counter = label_counter + 1;
      elseif ~is_same && ~cumulative
        label_counter = 1;
      end

      if ~cumulative
        data.(output{i})(j, 1) = label_counter;
      else
        data.(output{i})(j, 1) = label_counter{idx, 2};
      end

      previous_value = this_value;

    end

  end

end

function label_counter = reset_label_counter(label_counter)
  for i = 1:numel(label_counter)
    label_counter{i, 2} = 0;
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
