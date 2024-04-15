function data = Std(transformer, data)
  %
  % Compute the sample standard deviation.
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name of the variable to operate on.
  % :type  Input: char or array
  %
  % :param OmitNan: Optional. If ``false`` any column with nan values will return a nan value.
  %                           If ``true`` nan values are skipped. Defaults to ``false``.
  % :type  OmitNan: logical
  %
  % :param Output: Optional. The optional column names to write out to.
  %                    By default, computation is done in-place (i.e., input columnise overwritten).
  % :type  Output: char or array
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  overwrite = false;

  input = bids.transformers_list.get_input(transformer, data);
  output = bids.transformers_list.get_output(transformer, data, overwrite);

  if ~isempty(output)
    assert(numel(input) == numel(output));
  end

  if isfield(transformer, 'OmitNan')
    omit_nan = transformer.OmitNan;
  else
    omit_nan = false;
  end

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    output_column = [input{i} '_std'];
    if ~isempty(output)
      output_column = output{i};
    end

    data.(output_column) = std(data.(input{i}));
    if omit_nan
      nan_values = isnan(data.(input{i}));
      data.(output_column) = std(data.(input{i})(~nan_values));
    end

  end

end
