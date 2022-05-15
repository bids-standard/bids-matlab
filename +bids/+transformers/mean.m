function data = mean(transformer, data)
  %
  % Compute mean of a column.
  % Arguments:
  % Input(string, mandatory): The name of the variable to operate on.
  % Output (string, optional): the optional list of column names to write out to.
  % By default, computation is done in-place (i.e., input columnise overwritten).
  %
  % OmitNan
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  overwrite = false;

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data, overwrite);

  if ~isempty(output)
    assert(numel(input) == numel(output));
  end

  if isfield(transformer, 'OmitNan')
    omit_nan = transformer.OmitNan;
  else
    omit_nan = false;
  end

  for i = 1:numel(input)

    output_column = [input{i} '_mean'];
    if ~isempty(output)
      output_column = output{i};
    end

    if omit_nan
      data.(output_column) = mean(data.(input{i}), 'omitnan');

    else
      data.(output_column) = mean(data.(input{i}));

    end

  end

end
