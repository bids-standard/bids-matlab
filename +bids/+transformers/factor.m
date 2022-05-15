function data = factor(transformer, data)
  %
  %
  % Converts a nominal/categorical variable with N unique levels
  % to either N indicators (i.e., dummy-coding).
  %
  % Arguments:
  % Input (list; mandatory): the name(s) of the variable(s) to dummy-code.
  %
  % By default it is the first factor level when sorting in alphabetical order
  % (e.g., if a condition has levels 'dog', 'apple', and 'helsinki',
  % the default reference level will be 'apple').
  %
  %
  % (C) Copyright 2022 Remi Gau

  input = bids.transformers.get_input(transformer, data);

  for i = 1:numel(input)

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
