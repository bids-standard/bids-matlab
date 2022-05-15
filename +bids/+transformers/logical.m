function data = logical(transformer, data)
  %
  %
  % Each of these transformations takes 2 or more columns as input
  % and performs the corresponding logical operation
  % - inclusive or
  % - conjunction
  % - logical negation
  %
  %
  % returning a single column as output.
  %
  % If non-boolean input are passed, it is expected that all zero or nan (for numeric
  % data types), "NaN"
  % and empty (for strings) values will evaluate to false,
  % and all other values will evaluate to true.
  %
  % Arguments:
  %
  % - Input(list; mandatory): A list of 2 or more column names.
  % - Output(str; mandatory): The name of the output column.
  %
  %
  % Returns the logical negation of the input column(s). Uses Python-like boolean semantics.
  % That is, for every value that evaluates to True
  % (i.e., all non-zero or non-empty values), return 0,
  % and for every value that evaluates to False (i.e., zero or empty string) return 1.
  % Arguments:
  % Input(list, mandatory): A list containing one or more column names.
  % Output(list, optional): An optional list of output column names.
  % Must match the input list in length,
  % and column names will be mapped 1-to-1. If no output argument is provided,
  % defaults to in-place transformation (i.e., each input column will be overwritten).
  %
  %
  %
  % (C) Copyright 2022 Remi Gau

  % TODO
  % for Add Or, if not ouput just merge the name of the input variables

  input = bids.transformers.get_input(transformer, data);

  output = bids.transformers.get_output(transformer, data);
  assert(numel(output) == 1);

  % try coerce all input to logical
  for i = 1:numel(input)

    if iscell(data.(input{i}))
      tmp1 = ~cellfun('isempty', data.(input{i}));
      tmp2 = ~cellfun(@(x) all(isnan(x)), data.(input{i}));
      tmp(:, i) = all([tmp1 tmp2], 2);

    else
      tmp2 = data.(input{i});
      tmp2(isnan(tmp2)) = 0;
      tmp(:, i) = logical(tmp2);

    end

  end

  switch lower(transformer.Name)
    case 'and'
      data.(output{1}) = all(tmp, 2);
    case 'or'
      data.(output{1}) = any(tmp, 2);
    case 'not'
      % TODO "not" can only have one input
      data.(output{1}) = ~tmp;
  end

end
