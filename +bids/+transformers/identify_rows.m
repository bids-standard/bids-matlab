function rows = identify_rows(data, left, query_type, right)
  %
  % USAGE::
  %
  %     rows = identify_rows(data, left, query_type, right)
  %
  % EXAMPLE::
  %
  %   transformer = struct('Name', 'Filter', ...
  %                        'Input', 'sex', ...
  %                        'Query', 'age > 20');
  %
  %   data.sex = {'M', 'F', 'F', 'M'};
  %   data.age = [10, 21, 15, 26];
  %
  %   [left, query_type, right] = bids.transformers.get_query(transformer);
  %   rows = identify_rows(data, left, query_type, right);
  %
  %
  %
  % (C) Copyright 2022 BIDS-MATLAB developers

  if iscellstr(data.(left))

    if ismember(query_type, {'>', '<', '>=', '<='})
      msg = sprtinf(['Types "%s" are not supported for queries on string\n'...
                     'in query %s'], ...
                    {'>, <, >=, <='}, ...
                    query);
      bids.internal.error_handling(mfilename(), ...
                                   'unsupportedQueryType', ...
                                   msg, ...
                                   false);

    end

    rows = regexp(data.(left), right, 'match');
    rows = ~cellfun('isempty', rows);

  elseif isnumeric(data.(left))

    right = str2num(right);

    switch query_type

      case '=='
        rows = data.(left) == right;

      case '>'
        rows = data.(left) > right;

      case '<'
        rows = data.(left) < right;

      case '>='
        rows = data.(left) >= right;

      case '<='
        rows = data.(left) <= right;

    end

  end
end
