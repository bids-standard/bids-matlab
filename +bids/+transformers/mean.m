function data = mean(transformer, data)
  %
  % Compute mean of a column.
  % Arguments:
  % Input(string, mandatory): The name of the variable to operate on.
  % Output (string, optional): the optional list of column names to write out to.
  % By default, computation is done in-place (i.e., input columnise overwritten).
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

    output_column = [inputs{i} '_mean'];
    if ~isempty(outputs)
      output_column = outputs{i};
    end

    if omit_nan
      data.(output_column) = mean(data.(inputs{i}), 'omitnan');

    else
      data.(output_column) = mean(data.(inputs{i}));

    end

  end

end
