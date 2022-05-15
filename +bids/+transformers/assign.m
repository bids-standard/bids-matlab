function data = assign(transformer, data)
  %
  % (C) Copyright 2022 BIDS-MATLAB developers
  %
  % Assign(Input, Target, Output=None, InputAttr="value", TargetOutputAttr="value")

  % The Assign transformation assigns one or more variables or columns (specified as the input)
  % to one or more other columns (specified by target and/or output as described below).

  % Arguments:

  % Input (list; mandatory):
  % the name(s) of the columns from which attribute values are to be drawn
  % (for assignment to the attributes of other columns).
  % Must exactly match the length of the target argument.

  % Target (list, mandatory):
  % the name(s) of the columns to which
  % the attribute values taken from the input
  % are to be assigned.
  % Must exactly match the length of the input argument.
  % Names are mapped 1-to-1 from input to target.
  % Note that if no output argument is specified, the columns named in target are modified in-place.

  % Output (list; optional):
  % optional names of the columns to output the result of the assignment to.
  % Must exactly match the length of the input and target arguments.
  % If no output list is provided, columns named in target are modified in-place.
  % If an output list is provided, each column in the target list is first cloned,
  % then the reassignment from the input to the target is applied;
  % finally, the new (cloned and modified) column is written out to the column named in output.

  % InputAttr (str or list; optional):
  % specifies which attribute of the input column to assign.
  % Must be one of ``value``, ``onset``, or ``duration``. Defaults to ``value``.
  % If a list is passed, its length must exactly match that of the input and target lists.

  % TargetAttr (str or list; optional):
  % specifies which attribute of the output column to assign to.
  % Must be one of ``amplitude````value``, ``onset``, or ``duration``.
  % Defaults to value.
  % If a list is passed, its length must exactly match that of the input and target lists.

  % Examples:
  % To reassign the value property of a variable named ``response_time``
  % to the duration property of a ``face`` variable
  % (as one might do in order to, e.g., model trial-by-trial reaction time differences
  % for a given condition using a varying-epoch approach),
  % and write it out as a new ``face_modulated_by_RT`` column:

  % {
  %   "Name": "Assign",
  %   "Input": ["response_time"],
  %   "Target": ["face"],
  %   "TargetAttr": "duration",
  %   "Output": ["face_modulated_by_RT"]
  % }

  % Notes:
  % This transformation is non-destructive with respect to the input column(s).
  % In case where in-place assignment is desired (essentially, renaming a column),
  % either use the rename transformation, or set output to the same value as the input.

  % TODO check if attr are cells

  input = bids.transformers.get_input(transformer, data);
  target = get_target(transformer, data);

  output = bids.transformers.get_output(transformer, data, false);

  input_attr = get_attribute(transformer, input, 'InputAttr');
  target_attr = get_attribute(transformer, input, 'TargetAttr');

  for i = 1:numel(input)

    if ~isempty(output)
      assign_to = output{i};
    else
      assign_to = target{i};
    end

    % grab the data that is being assigned somewhere else
    % TODO deal with cell
    % TODO deal with grabbing only certain rows?
    switch input_attr{i}

      case 'value'
        to_assign = data.(input{i});

      case {'onset', 'duration'}

        attr_to_assign = data.(input_attr{i});

        if strcmp(target_attr, 'value')
          to_assign = attr_to_assign;
        else
          to_assign = data.(input{i});
        end

      otherwise
        bids.internal.error_handling(mfilename(), 'wrongAttribute', ...
                                     'InputAttr must be one of "value", "onset", "duration"', ...
                                     false);

    end

    if ~ismember(target_attr{i}, {'value', 'onset', 'duration'})
      bids.internal.error_handling(mfilename(), 'wrongAttribute', ...
                                   'InputAttr must be one of "value", "onset", "duration"', ...
                                   false);
    end

    if strcmp(target_attr, 'value')

      data.(assign_to) = to_assign;

    else

      fields = fieldnames(data);
      for j = 1:numel(fields)

        if ismember(fields{j}, {assign_to, input{i}})
          continue

        elseif ismember(fields{j}, {target_attr{i}})
          data.(target_attr{i}) = cat(1, data.(target_attr{i}), to_assign);

        elseif ismember(fields{j}, {'onset', 'duration'})
          data.(fields{j}) = repmat(data.(fields{j}), 2, 1);

        else

          % pad non concerned fields with nan
          data = pad_with_nans(data, fields{j}, to_assign);
        end

      end

      % pad concerned fields
      data.(assign_to) = cat(1, nan(size(to_assign)), data.(assign_to));
      data = pad_with_nans(data, input{i}, to_assign);

    end

  end

end

function data = pad_with_nans(data, field, to_assign)

  if iscell(data.(field))
    data.(field) = cat(1, data.(field), repmat({nan}, numel(to_assign), 1));
  else
    data.(field) = cat(1, data.(field), nan(size(to_assign)));
  end

end

function attr = get_attribute(transformer, input, type)

  attr = {'value'};
  if isfield(transformer, type)
    attr = transformer.(type);
    if ischar(attr)
      attr = {attr};
    end
    if numel(attr) > 1 && numel(attr) ~= numel(input)
      bids.internal.error_handling(mfilename(), 'missingAttribute', ...
                                   sprintf(['If number of %s must be equal to 1 ', ...
                                            'or to the number of Inputs'], type), ...
                                   false);
    end
  end

end

function target = get_target(transformer, data)

  if isfield(transformer, 'Target')

    target = transformer.Target;

    if isempty(target)
      target = {};
      if isfield(transformer, 'verbose')
        warning('empty "Target" field');
      end
      return

    else
      bids.transformers.check_field(transformer.Target, data, 'Target', false);

    end

    target = {target};

  else
    target = {};

  end

end
