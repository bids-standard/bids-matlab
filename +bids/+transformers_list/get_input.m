function input = get_input(transformer, data)
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  assert(isstruct(transformer));
  assert(numel(transformer) == 1);

  verbose = true;
  if isfield(transformer, 'verbose')
    verbose = transformer.verbose;
  end

  tolerant = true;
  if isfield(transformer, 'tolerant')
    tolerant = transformer.tolerant;
  end

  if isfield(transformer, 'Input')

    input = transformer.Input;

    if isempty(input)
      input = {};
      bids.internal.error_handling(mfilename(), ...
                                   'emptyInputField', ...
                                   'empty "Input" field', ...
                                   tolerant, ...
                                   verbose);
      return
    end

  else
    input = {};
    return

  end

  if ~iscell(input)
    input = {input};
  end

  bids.transformers_list.check_field(input, data, 'Input', tolerant);

end
