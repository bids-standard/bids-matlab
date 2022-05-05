function data = split(transformer, data)
  %
  %
  %
  % Split a variable into N variables as defined by the levels of one or more other variables.
  %
  % Arguments:
  %
  % Input(list, mandatory): The name of the variable(s) to operate on.
  %
  % By(string, mandatory): Name(s) for variable(s) to split on.
  %
  % Output (list, optional): the optional list of column names to write out to.
  %
  % If an output list is provided,
  % it must have the same number of values as the number of generated columns.
  %
  % If no output list is provided, name components will be separated by a period,
  % and values of variables will be enclosed in square brackets.
  %
  % For example,  given a variable Condition
  % that we wish to split on two categorical columns A and B,
  % where a given row has values A=a and B=1,
  % the generated name will be Condition.A[a].B[1].
  %
  %
  %
  % (C) Copyright 2022 Remi Gau

  inputs = bids.transformers.get_input(transformer, data);
  outputs = bids.transformers.get_output(transformer, data);
  by = transformer.By;

  available_variables = fieldnames(data);
  available_by = ismember(by, available_variables);
  if ~all(available_by)
    msg = sprintf('missing variable(s) to split by: "%s"', ...
                  strjoin(input(~available_input), '", "'));
    bids.internal.error_handling(mfilename(), 'missingInput', msg, false);
  end

  for i = 1:numel(inputs)

    this_input = data.(inputs{i});

    levels = unique(data.(by{1}));

    for j = 1:numel(levels)

      field = [inputs{i} '_' levels{j}];
      field = regexprep(field, '[^a-zA-Z0-9_]', '');

      rows_to_keep = ismember(data.(by{1}), levels{j});

      data.(field) = this_input(rows_to_keep);
    end

  end

end
