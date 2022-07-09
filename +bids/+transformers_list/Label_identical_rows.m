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

    previous_value = [];
    label = 1;

    for j = 1:numel(data.(input{i}))

      is_same = false;

      this_value = data.(input{i})(j);
      if iscell(this_value)
        this_value = this_value{1};
      end

      if isempty(previous_value) % first row
      elseif all(isnumeric([this_value, previous_value])) && this_value == previous_value
        is_same = true;
      elseif all(ischar([this_value, previous_value])) && strcmp(this_value, previous_value)
        is_same = true;
      end

      if is_same
        label = label + 1;
      else
        label = 1;
      end

      data.(output{i})(j, 1) = label;

      previous_value = this_value;

    end

  end

end
