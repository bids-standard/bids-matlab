function data = Factor(transformer, data)
  %
  % Converts a nominal/categorical variable with N unique levels
  % to either N indicators (i.e., dummy-coding).
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name(s) of the variable(s) to dummy-code.
  % :type  Input: char or array
  %
  % By default it is the first factor level when sorting in alphabetical order
  % (e.g., if a condition has levels 'dog', 'apple', and 'helsinki',
  % the default reference level will be 'apple').
  %
  % The name of the output columns for 2 input columns ``gender`` and ``age``
  % with 2 levels (``M``, ``F``) and (``20``, ``30``) respectivaly
  % will of the shape:
  %
  % - ``gender_F_age_20``
  % - ``gender_F_age_20``
  % - ``gender_M_age_30``
  % - ``gender_M_age_30``
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    this_input = data.(input{i});

    % coerce to cellstr
    % and get name to append for each level
    if iscellstr(this_input)
      level_names = [];

    elseif isnumeric(this_input)
      this_input = cellstr(num2str(this_input));
      level_names = unique(this_input);

    elseif ischar(this_input)
      this_input = cellstr(this_input);
      level_names = [];

    end

    levels = unique(this_input);
    if isempty(level_names)
      level_names = cellstr(num2str([1:numel(levels)]'));
    end

    % generate new variables
    for j = 1:numel(levels)
      field = [input{i} '_' level_names{j}];
      field = regexprep(field, '[^a-zA-Z0-9_]', '');
      data.(field) = ismember(this_input, levels{j});
    end

  end

end
