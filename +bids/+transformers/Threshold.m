function data = Threshold(transformer, data)
  %
  % Thresholds input values at a specified cut-off and optionally binarizes the result.
  %
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %       {
  %         "Name":  "Threshold",
  %         "Input": "onset",
  %         "Threshold": 0.5,
  %         "Binarize": true,
  %         "Output": "delayed_onset"
  %       }
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**.  The name(s)of the column(s) to threshold/binarize.
  % :type  Input: string or array
  %
  % :param Threshold: optional. The cut-off to use for thresholding. Defaults to ``0``.
  % :type  Threshold: float
  %
  % :param Binarize: optional. If ``true``, thresholded values will be binarized
  %                            (i.e., all non-zero values will be set to 1).
  %                            Defaults to ``false``.
  % :type Binarize: boolean
  %
  % :param Above: optional. Specifies which values to retain with respect to the cut-off.
  %                         If ``true``, all value above the threshold will be kept;
  %                         if ``false``, all values below the threshold will be kept.
  %                         Defaults to ``true``.
  % :type  Above: boolean
  %
  % :param Signed: optional. Specifies whether to treat the threshold
  %                          as signed (default) or unsigned.
  % :type  Signed: boolean
  %
  % For example, when passing above=true and threshold=3,
  % if signed=true, all and only values above +3 would be retained.
  % If signed=false, all absolute values > 3 would be retained
  % (i.e.,values in  the range -3 < X < 3 would be set to 0).
  %
  % :param Output: optional. Optional names of columns to output.
  %                          Must match length of input column if provided,
  %                          and columns will be mapped 1-to-1 in order.
  %                          If no output values are provided,
  %                          the threshold transformation is applied
  %                          in-place to all the inputs.
  % :type  Output: string or array
  %
  %
  % **CODE EXAMPLE**::
  %
  %   transformer = struct('Name', 'Threshold', ...
  %                         'Input', 'onset', ...
  %                         'Value', 3, ...
  %                         'Ouput', 'onset_minus_3');
  %
  %   data.onset =
  %
  %   data = bids.transformers(transformer, data);
  %
  %   data.onset_minus_3 =
  %
  %   ans =
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers.get_input(transformer, data);
  output = bids.transformers.get_output(transformer, data);

  threshold = 0;
  binarize = false;
  above = true;
  signed = true;

  if isfield(transformer, 'Threshold')
    threshold = transformer.Threshold;
  end

  if isfield(transformer, 'Binarize')
    binarize = transformer.Binarize;
  end

  if isfield(transformer, 'Above')
    above = transformer.Above;
  end

  if isfield(transformer, 'Signed')
    signed = transformer.Signed;
  end

  for i = 1:numel(input)

    valuesToThreshold = data.(input{i});

    if ~signed
      valuesToThreshold = abs(valuesToThreshold);
    end

    if above
      idx = valuesToThreshold > threshold;
    else
      idx = valuesToThreshold < threshold;
    end

    tmp = zeros(size(data.(input{i})));
    tmp(idx) = data.(input{i})(idx);

    if binarize
      tmp(idx) = 1;
    end

    data.(output{i}) = tmp;
  end

end