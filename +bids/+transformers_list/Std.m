function data = Std(transformer, data)
  %
  % Compute the sample standard deviation.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %       {
  %         "Name":  "Std",
  %         "Input": "reaction_time",
  %         "OmitNan": false,
  %         "Output": "std_RT"
  %       }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The name of the variable to operate on.
  % :type  Input: string or array
  %
  % :param OmitNan: Optional. If ``false`` any column with nan values will return a nan value.
  %                           If ``true`` nan values are skipped. Defaults to ``false``.
  % :type  OmitNan: logical
  %
  % :param Output: Optional. The optional column names to write out to.
  %                    By default, computation is done in-place (i.e., input columnise overwritten).
  % :type  Output: string or array
  %
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Std', ...
  %                         'Input', 'reaction_time', ...
  %                         'OmitNan', false, ...
  %                         'Ouput', 'std_RT');
  %
  %   data.reaction_time = TODO
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.std_RT = TODO
  %
  %   ans = TODO
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
