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
  % (C) Copyright 2022 Remi Gau

  % treat By as a stack
  %
  % work recursively
  %
  %  - apply first element of By to all Input
  %  - we keep track of the new inputs that will be used for the next element of By
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

    inputs = transformer.Input;

    % TODO
    % outputs = bids.transformers.get_output(transformer, data);

    for i = 1:numel(inputs)

      if isfield(data, inputs{i})
        error('New field %s already exist in data.', inputs{i});
      end

      sourcefield = transformer.source{i};
      rows_to_keep = transformer.rows_to_keep{i};

      data.(inputs{i}) = data.(sourcefield)(rows_to_keep);

    end

    return

  end

  transformer.By = sort(transformer.By);

  % initialise for recursion
  if ~isfield(transformer, 'rows_to_keep')

    inputs = bids.transformers.get_input(transformer, data);
    inputs = unique(inputs);

    if isempty(inputs)
      return
    end

    % make sure all variables to split by are there
    bids.transformers.check_field(transformer.By, data, 'By');

    transformer.source = inputs;

    % assume all rows are potentially ok at first
    for i = 1:numel(inputs)
      transformer.rows_to_keep{i} = ones(size(data.(inputs{i})));
    end

  else

    inputs = transformer.Input;

  end

  new_inputs = {};
  new_rows_to_keep = {};
  new_source = {};

  % pop the stack
  by = transformer.By{1};
  this_by = data.(by);
  transformer.By(1) = [];

  % treat inputs as a queue
  for i = 1:numel(inputs)

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
        field = [inputs{i} '_BY_' by '_' num2str(this_level)];
      else
        field = [inputs{i} '_BY_' by '_' this_level];
      end
      field = bids.transformers.coerce_fieldname(field);

      new_source{end + 1} = transformer.source{i};
      new_rows_to_keep{end + 1} = all([transformer.rows_to_keep{i} ...
                                       ismember(this_by, this_level)], ...
                                      2);
      new_inputs{end + 1} = field;

    end

  end

  transformer.Input = new_inputs;
  transformer.rows_to_keep = new_rows_to_keep;
  transformer.source = new_source;

  data = bids.transformers.split(transformer, data);

end
