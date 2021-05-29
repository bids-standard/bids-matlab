function error_handling(varargin)
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  default_function_name = 'bidsMatlab';
  default_id = 'unspecified';
  default_msg = 'unspecified';
  default_tolerant = true;
  default_verbose = false;

  p = inputParser;

  addOptional(p, 'function_name', default_function_name, @ischar);
  addOptional(p, 'id', default_id, @ischar);
  addOptional(p, 'msg', default_msg, @ischar);
  addOptional(p, 'tolerant', default_tolerant, @islogical);
  addOptional(p, 'verbose', default_verbose, @islogical);

  parse(p, varargin{:});

  function_name = bids.internal.file_utils(p.Results.function_name, 'basename');

  id = [function_name, ':' p.Results.id];

  if ~p.Results.tolerant
    errorStruct.identifier = id;
    errorStruct.message = p.Results.msg;
    error(errorStruct);
  end

  if p.Results.verbose
    warning(id, p.Results.msg);
  end

end
