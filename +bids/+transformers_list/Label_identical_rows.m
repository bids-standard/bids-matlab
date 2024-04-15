function data = Label_identical_rows(transformer, data)
  %
  % Creates an extra column to index consecutive identical rows in a column.
  % The index restarts at 1 with every change of row content.
  % This can for example be used to label consecutive events of the same trial_type in
  % a block.
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name(s) of the variable(s) to operate on.
  % :type  Input: char or array
  %
  % :param Cumulative: **optional**. Defaults to ``False``.
  %                    If ``True``, the labels are not reset to 0
  %                    when encountering new row content.
  % :type  Cumulative: logical
  %
  % .. note::
  %
  %     The labels will be by default be put in a column called Input(i)_label
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  % TODO: label only if cell content matches some condition

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data);

  cumulative = false;
  if isfield(transformer, 'Cumulative')
    cumulative = transformer.Cumulative;
  end

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    if strcmp(output{i}, input{i})
      output{i} = [output{i} '_label'];
    end

    if isfield(data, output{i})
      bids.internal.error_handling(mfilename(), ...
                                   'outputFieldAlreadyExist', ...
                                   sprintf('The output field already "%s" exists', output{i}), ...
                                   false);
    end

    this_input = data.(input{i});
    if ischar(this_input)
      this_input = {this_input};
    end

    % Use a cell to keep track of the occurrences of each value of this_input
    label_counter = init_label_counter(this_input, cumulative);

    previous_value = [];

    for j = 1:numel(this_input)

      this_value = this_input(j);
      if iscell(this_value)
        this_value = this_value{1};
      end

      is_same = compare_rows(this_value, previous_value);

      if cumulative || (~cumulative && is_same)
        label_counter = increment_label_counter(label_counter, this_value);

      elseif ~is_same && ~cumulative
        label_counter = reset_label_counter(label_counter, cumulative);
      end

      idx = get_index(this_value, label_counter);
      data.(output{i})(j, 1) = label_counter{idx, 2};

      previous_value = this_value;

    end

  end

end

function label_counter = init_label_counter(this_input, cumulative)

  if isnumeric(this_input)

    label_counter = unique(this_input);

    % Only keep one nan
    nan_values = find(isnan(label_counter));
    label_counter(nan_values(2:end)) = [];

    label_counter = num2cell(label_counter);

  elseif iscellstr(this_input)
    label_counter = unique(this_input);

  else

    % get unique char first then numeric
    idx = cellfun(@(x) ischar(x), this_input);
    tmp = this_input(idx);
    label_counter_char = init_label_counter(tmp, cumulative);

    idx = cellfun(@(x) isnumeric(x), this_input);
    tmp = this_input(idx);
    tmp = cell2mat(tmp);
    label_counter_num = init_label_counter(tmp, cumulative);

    label_counter = cat(1, label_counter_char, label_counter_num);

  end

  if isempty(label_counter)
    label_counter = {'', 0};
  end

  label_counter = reset_label_counter(label_counter, cumulative);

end

function argout = get_index(this_value, label_counter)
  if isnan(this_value)
    argout = cellfun(@(x) isnumeric(x) && isnan(x), label_counter(:, 1));
  elseif isnumeric(this_value)
    argout = cellfun(@(x) isnumeric(x) && x == this_value, label_counter(:, 1));
  elseif ischar(this_value)
    argout = cellfun(@(x) ischar(x) && strcmp(x, this_value), label_counter(:, 1));
  end
  argout = find(argout);
end

function label_counter = increment_label_counter(label_counter, this_value)
  idx = get_index(this_value, label_counter);
  label_counter{idx, 2} = label_counter{idx, 2} + 1;
end

function label_counter = reset_label_counter(label_counter, cumulative)
  default_value = 1;
  if cumulative
    default_value = 0;
  end
  for i = 1:size(label_counter, 1)
    label_counter{i, 2} = default_value;
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
