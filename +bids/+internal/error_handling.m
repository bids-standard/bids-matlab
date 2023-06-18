function error_handling(varargin)
  %
  % USAGE::
  %
  %     error_handling(function_name, id, msg, tolerant, verbose)
  %
  % :param function_name: default = ``bidsMatlab``
  % :type function_name:
  %
  % :param id: default = ``unspecified``
  % :type id: char
  %
  % :param msg: default = ``unspecified``
  % :type msg: char
  %
  % :param tolerant:
  % :type tolerant: logical
  %
  % :param verbose:
  % :type verbose:  logical
  %
  % Example
  % -------
  %
  % .. code-block:: matlab
  %
  %   bids.internal.error_handling(mfilename(), 'thisError', 'this is an error', tolerant, verbose)
  %

  % (C) Copyright 2018 BIDS-MATLAB developers

  default_function_name = 'bidsMatlab';
  default_id = 'unspecified';
  default_msg = 'unspecified';
  default_tolerant = true;
  default_verbose = false;

  args = inputParser;

  addOptional(args, 'function_name', default_function_name, @ischar);
  addOptional(args, 'id', default_id, @ischar);
  addOptional(args, 'msg', default_msg, @ischar);
  addOptional(args, 'tolerant', default_tolerant, @islogical);
  addOptional(args, 'verbose', default_verbose, @islogical);

  parse(args, varargin{:});

  function_name = bids.internal.file_utils(args.Results.function_name, 'basename');

  id = [function_name, ':' args.Results.id];
  msg = sprintf(['\n' args.Results.msg '\n']);

  if ~args.Results.tolerant
    errorStruct.identifier = id;
    errorStruct.message = msg;
    error(errorStruct);
  end

  if args.Results.verbose
    warning(id, msg);
  end

end
