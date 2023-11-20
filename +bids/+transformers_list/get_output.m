function output = get_output(transformer, data, overwrite)
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  if nargin < 3
    overwrite = true;
  end

  if isfield(transformer, 'Output') && ~isempty(transformer.Output)

    output = transformer.Output;

    if ~iscell(output)
      output = {output};
    end

  else

    % will overwrite input columns
    if overwrite
      input = bids.transformers_list.get_input(transformer, data);
      output = input;
    else
      output = {};
    end

  end

  for i = 1:numel(output)
    output{i} = bids.transformers_list.coerce_fieldname(output{i});
  end

end
