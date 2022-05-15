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
  % the generated name will be Condition_BY_A_a_BY_B_1.
  %
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  % treat By as a stack
  %
  % work recursively
  %
  %  - apply first element of By to all Input
  %  - we keep track of the new input that will be used for the next element of By
  %  - we keep track of which rows to keep for each original source input
  %  - we keep track of the source input through the recursions

  % We are done recursing. Do the actual splitting
  if isempty(transformer.By)

    if ~isfield(transformer, 'rows_to_keep')
      if isfield(transformer, 'verbose')
        % in case user gave an empty By
        warning('empty "By" field');
      end
      return
    end

    input = transformer.Input;

    % TODO
    % output = bids.transformers.get_output(transformer, data);

    for i = 1:numel(input)

      if isfield(data, input{i})
        error('New field %s already exist in data.', input{i});
      end

      sourcefield = transformer.source{i};
      rows_to_keep = transformer.rows_to_keep{i};

      data.(input{i}) = data.(sourcefield)(rows_to_keep);

    end

    return

  end

  transformer.By = sort(transformer.By);

  % initialise for recursion
  if ~isfield(transformer, 'rows_to_keep')

    input = bids.transformers.get_input(transformer, data);
    input = unique(input);

    if isempty(input)
      return
    end

    % make sure all variables to split by are there
    bids.transformers.check_field(transformer.By, data, 'By');

    transformer.source = input;

    % assume all rows are potentially ok at first
    for i = 1:numel(input)
      transformer.rows_to_keep{i} = ones(size(data.(input{i})));
    end

  else

    input = transformer.Input;

  end

  new_input = {};
  new_rows_to_keep = {};
  new_source = {};

  % pop the stack
  by = transformer.By{1};
  this_by = data.(by);
  transformer.By(1) = [];

  % treat input as a queue
  for i = 1:numel(input)

    % deal with nans
    if iscell(this_by)
      nan_values = cellfun(@(x) all(isnan(x)), this_by);
      if any(nan_values)
        this_by(nan_values) = repmat({'NaN'}, 1, sum(nan_values));
      end
    end

    levels = unique(this_by);

    if isempty(levels)
      continue
    end

    for j = 1:numel(levels)

      if iscell(levels)
        this_level = levels{j};
      else
        this_level = levels(j);
      end

      % create the new field name and make sure it is valid
      if isnumeric(this_level)
        field = [input{i} '_BY_' by '_' num2str(this_level)];
      else
        field = [input{i} '_BY_' by '_' this_level];
      end
      field = bids.transformers.coerce_fieldname(field);

      % store rows, source and input for next iteration
      if strcmp(this_level, 'NaN')
        new_rows_to_keep{end + 1} = all([transformer.rows_to_keep{i} ...
                                         cellfun(@(x) all(isnan(x)), this_by)], ...
                                        2);
      else
        new_rows_to_keep{end + 1} = all([transformer.rows_to_keep{i} ...
                                         ismember(this_by, this_level)], ...
                                        2);
      end
      new_source{end + 1} = transformer.source{i};
      new_input{end + 1} = field;

    end

  end

  transformer.Input = new_input;
  transformer.rows_to_keep = new_rows_to_keep;
  transformer.source = new_source;

  data = bids.transformers.split(transformer, data);

end
