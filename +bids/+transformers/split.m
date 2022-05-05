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

  for i = 1:numel(inputs)

    this_input = data.(inputs{i});

    data.(outputs{i}) = this_input;

  end

end
