function data = std(transformer, data)
  %
  % Compute the sample standard deviation.
  % Arguments:
  % Input(list, mandatory): The name(s) of the variable(s) to operate on.
  % Output (list, optional): Optional names of columns to output.
  % Must match length of input column if provided, and columns will be mapped 1-to-1 in order.
  % If no output values are provided, the transformation is applied in-place to all the input.
  %
  % OmitNan
  %
  % (C) Copyright 2022 Remi Gau

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

    output_column = [input{i} '_std'];
    if ~isempty(output)
      output_column = output{i};
    end

    if omit_nan
      data.(output_column) = std(data.(input{i}), 'omitnan');

    else
      data.(output_column) = std(data.(input{i}));

    end

  end

end
