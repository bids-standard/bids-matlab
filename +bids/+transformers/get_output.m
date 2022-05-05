function output = get_output(transformer, data, overwrite)
  %
  %
  % (C) Copyright 2022 Remi Gau
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
      output = bids.transformers.get_input(transformer, data);
    else
      output = {};
    end
  end
end