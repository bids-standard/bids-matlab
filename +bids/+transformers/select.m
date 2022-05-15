function data = select(transformer, data)
  %
  % The select transformation specifies which columns to retain for subsequent analysis.
  % Any columns that are not specified here will be dropped.
  %
  % **JSON EXAMPLE**:
  %
  % .. code-block:: json
  %
  %     {
  %       "Name": "Select",
  %       "Input": [
  %           "trial_type",
  %           "reaction_time"
  %       ]
  %     }
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The names of all columns to keep.
  %                              Any columns not in this list will be deleted and
  %                              will not be available to any subsequent transformations
  %                              or downstream analyses.
  % :type  Input: array
  %
  % .. note::
  %
  %   one can think of select as the inverse the ``Delete`` transformation
  %   that removes all named columns from further analysis.
  %
  % **CODE EXAMPLE**::
  %
  %     TODO
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers.get_input(transformer, data);

  for i = 1:numel(input)
    tmp.(input{i}) = data.(input{i});
  end

  data = tmp;
end
