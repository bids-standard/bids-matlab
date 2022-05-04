function output = get_output(transformer)
  %
  %
  % (C) Copyright 2022 Remi Gau
  if isfield(transformer, 'Output') && ~isempty(transformer.Output)
    output = transformer.Output;
    if ~iscell(output)
      output = {output};
    end
  else
    % will overwrite input columns
    output = bids.transformers.get_input(transformer);
  end
end
