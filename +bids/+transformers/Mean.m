function data = Mean(transformer, data)
  %
  % Compute mean of a column.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %       {
  %         "Name":  "Mean",
  %         "Input": "reaction_time",
  %         "OmitNan": false,
  %         "Output": "mean_RT"
  %       }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name of the variable to operate on.
  % :type  Input: string or array
  %
  % :param OmitNan: optional. If ``false`` any column with nan values will return a nan value.
  %                           If ``true`` nan values are skipped. Defaults to ``false``.
  % :type  OmitNan: boolean
  %
  % :param Output: optional. The optional column names to write out to.
  %                    By default, computation is done in-place (i.e., input columnise overwritten).
  % :type  Output: string or array
  %
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Mean', ...
  %                         'Input', 'reaction_time', ...
  %                         'OmitNan', false, ...
  %                         'Ouput', 'mean_RT');
  %
  %   data.reaction_time =
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.mean_RT =
  %
  %   ans =
  %
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
