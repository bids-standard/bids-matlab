function error_handling(varargin)
  %
  % USAGE::
  %
  %     error_handling(function_name, id, msg, tolerant, verbose)
  %
  % :param function_name: default = ``bidsMatlab``
  % :type function_name:
  % :param id: default = ``unspecified``
  % :type id: string
  % :param msg: default = ``unspecified``
  % :type msg: string
  % :param tolerant:
  % :type tolerant: boolean
  % :param verbose:
  % :type verbose:  boolean
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
  msg = p.Results.msg;

  if ~p.Results.tolerant
    errorStruct.identifier = id;
    errorStruct.message = msg;
    error(errorStruct);
  end

  if p.Results.verbose
    warning(id, msg);
  end

end
