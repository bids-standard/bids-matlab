function input = get_input(transformer, data)
  %
  %
  % (C) Copyright 2022 Remi Gau

  assert(isstruct(transformer));
  assert(numel(transformer) == 1);

  if isfield(transformer, 'Input') && ~isempty(transformer.Input)
    input = transformer.Input;
  else
    input = {};
    return
  end

  if ~iscell(input)
    input = {input};
  end

  available_variables = fieldnames(data);
  available_input = ismember(input, available_variables);
  if ~all(available_input)
    msg = sprintf('missing variable(s): "%s"', strjoin(input(~available_input), '", "'));
    bids.internal.error_handling(mfilename(), 'missingInput', msg, false);
  end

end
