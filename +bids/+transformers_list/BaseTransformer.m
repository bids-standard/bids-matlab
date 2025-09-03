classdef BaseTransformer
  %
  % WIP in case we need to object oriented
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  properties

    input % cell
    output % cell
    data % structure
    verbose = false % logical
    overwrite = true % logical

  end

  methods

    function obj = BaseTransformer(varargin)

      args = inputParser;

      args.addOptional('transformer', struct([]), @isstruct);
      args.addOptional('data', struct([]), @isstruct);
      args.addOptional('overwrite', obj.overwrite, @islogical);
      args.addOptional('verbose', obj.verbose, @islogical);

      args.parse(varargin{:});

      obj.overwrite = args.Results.overwrite;
      obj.verbose = args.Results.verbose;

      if ~isempty(args.Results.transformer)
        obj.input = obj.get_input(args.Results.transformer);
        obj.output = obj.get_output(args.Results.transformer);
      end

      if ~isempty(args.Results.data)
        obj.data = args.Results.data;
        obj.check_input(obj.input, obj.data);
      end

    end

    %% Getters
    function value = get.input(obj)
      value = obj.input;
    end

    function value = get.output(obj)
      value = obj.output;
    end

    function data = get.data(obj)
      data = obj.data;
    end

    %% Setters
    function obj = set.input(obj, input)
      obj.input = input;
    end

    function obj = set.data(obj, data)
      obj.data = data;
    end

    function obj = set.output(obj, output)
      obj.output = output;
    end

    %% complex getters
    function input = get_input(obj, transformer)

      if nargin < 2
        input = obj.input;
        return
      end

      assert(isstruct(transformer));
      assert(isscalar(transformer));

      if isfield(transformer, 'Input')

        input = transformer.Input;

        input = validate_input(obj, input);

      else
        input = {};
        return

      end

    end

    function output = get_output(obj, transformer)

      if nargin < 2
        output = obj.output;
        return
      end

      assert(isstruct(transformer));
      assert(isscalar(transformer));

      if isfield(transformer, 'Output')

        output = transformer.Output;

        output = validate_output(obj, output);

      else
        if obj.overwrite
          output = obj.input;
        else
          output = {};
        end

      end

    end

    function data = get_data(obj, field, rows)
      if nargin < 3
        data = obj.data(field);
      else
        data = obj.data(field);
        data = data(rows);
      end
    end

    %%
    function check_field(obj, field_list, data, field_type)
      %
      % check that each field in field_list is present
      % in the data structure
      %

      available_variables = fieldnames(data);

      available_from_fieldlist = ismember(field_list, available_variables);

      if ~all(available_from_fieldlist)
        msg = sprintf('missing variable(s): "%s"', ...
                      strjoin(field_list(~available_from_fieldlist), '", "'));
        bids.internal.error_handling(mfilename(), ['missing' field_type], msg, false);
      end

    end

    function check_input(obj, input, data)
      obj.check_field(input, data, 'Input');
    end

  end

  methods (Access = private)

    function input = validate_input(obj, input)

      if isempty(input)
        input = {};
        if obj.verbose
          warning('empty "Input" field');
        end
        return
      end

      if ~iscell(input)
        input = {input};
      end

    end

    function output = validate_output(obj, output)

      if isempty(output)
        output = {};
        if obj.verbose
          warning('empty "Output" field');
        end
        return

      else
        if obj.overwrite
          output = obj.input;
        else
          output = {};
        end

      end

      if ~iscell(output)
        output = {output};
      end

    end

  end

end
