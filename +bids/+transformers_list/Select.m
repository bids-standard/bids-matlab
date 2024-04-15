function data = Select(transformer, data)
  %
  % The select transformation specifies which columns to retain for subsequent analysis.
  %
  % Any columns that are not specified here will be dropped.
  %
  % The only exception is when dealing with data with ``onset`` and ``duration``
  % columns (from ``*_events.tsv`` files) in this case the onset and duration column
  % are also automatically selected.
  %
  %
  % Arguments:
  %
  % :param Input: **mandatory**. The names of all columns to keep.
  %                              Any columns not in this array will be deleted and
  %                              will not be available to any subsequent transformations
  %                              or downstream analyses.
  % :type  Input: char or array
  %
  % .. note::
  %
  %   one can think of select as the inverse the ``Delete`` transformation
  %   that removes all named columns from further analysis.
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  input = bids.transformers_list.get_input(transformer, data);

  for i = 1:numel(input)

    if ~isfield(data, input{i})
      continue
    end

    tmp.(input{i}) = data.(input{i});
  end

  % also grab onset and duration for events
  if bids.transformers_list.is_run_level(data)
    tmp.onset = data.onset;
    tmp.duration = data.duration;
  end

  data = tmp;
end
