function input = get_input(transformer)
  %
  %
  % (C) Copyright 2022 Remi Gau
  if isfield(transformer, 'Input') && ~isempty(transformer.Input)
    input = transformer.Input;
  else
    input = {};
  end

  if ~iscell(input)
    input = {input};
  end

end
