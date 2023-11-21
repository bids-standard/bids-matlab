function [left, query_type, right] = get_query(transformer)
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  supported_types = {'>=', '<=', '==', '~=', '>', '<'};

  if ~isfield(transformer, 'Query') || isempty(transformer.Query)
    bids.internal.error_handling(mfilename(), 'emptyQuery', ...
                                 'empty query', ...
                                 true);
    left = '';
    query_type = '';
    right = '';
    return

  else
    query = transformer.Query;

  end

  % should not happen because only one query is allowed
  % but in case the user did input things into a cell
  if iscell(query)
    query = query{1};
  end

  % identify query type
  for i = 1:numel(supported_types)
    sts = strfind(query, supported_types{i});
    if ~isempty(sts)
      query_type = supported_types{i};
      break
    end
  end

  if isempty(query_type)
    bids.internal.error_handling(mfilename(), ...
                                 'unknownQueryType', ...
                                 sprtinf(['Could not identify any of the supported types\n %s\n'...
                                          'in query %s'], supported_types, query), ...
                                 false);
  end

  tokens = regexp(query, query_type, 'split');
  left = strtrim(tokens{1});
  right = strtrim(tokens{2});

end
