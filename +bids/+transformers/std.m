function data = std(transformer, data)
  %
  % Compute the sample standard deviation.
  % Arguments:
  % Input(list, mandatory): The name(s) of the variable(s) to operate on.
  % Output (list, optional): Optional names of columns to output.
  % Must match length of input column if provided, and columns will be mapped 1-to-1 in order.
  % If no output values are provided, the transformation is applied in-place to all the inputs.
  %
  %
  % (C) Copyright 2022 Remi Gau

  overwrite = false;

  inputs = bids.transformers.get_input(transformer);
  outputs = bids.transformers.get_output(transformer, overwrite);

  if ~isempty(outputs)
    assert(numel(inputs) == numel(outputs));
  end

  if isfield(transformer, 'OmitNan')
    omit_nan = transformer.OmitNan;
  else
    omit_nan = false;
  end

  for i = 1:numel(inputs)

    if ~isfield(data, inputs{i})
      % TODO throw warning
      continue
    end

    output_column = [inputs{i} '_std'];
    if ~isempty(outputs)
      output_column = outputs{i};
    end

    if omit_nan
      data.(output_column) = std(data.(inputs{i}), 'omitnan');

    else
      data.(output_column) = std(data.(inputs{i}));

    end

  end

end
