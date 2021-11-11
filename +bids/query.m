function result = query(BIDS, query, varargin)
  %
  % Queries a directory structure formatted according to the BIDS standard
  %
  % USAGE::
  %
  %   result = bids.query(BIDS, query, ...)
  %
  % :param BIDS: BIDS directory name or BIDS structure (from bids.layout)
  % :type  BIDS: strcuture or string
  % :param query: type of query (see list below)
  % :type  query: string
  %
  % Type of query allowed:
  %
  %     - ``'sessions'``
  %     - ``'subjects'``
  %     - ``'modalities'``
  %     - ``'tasks'``
  %     - ``'runs'``
  %     - ``'suffixes'``
  %     - ``'entities'``
  %     - ``'data'``
  %     - ``'metadata'``
  %     - ``'metafiles'``
  %     - ``'dependencies'``
  %     - ``'extensions'``
  %     - ``'prefixes'``
  %
  %
  % .. warning:: Note that all the query types are plurals.
  %
  % Queries can "filtered" by passing more arguments key-value pairs as a list of
  % strings or as a cell or a structure.
  %
  % Note that for the entities listed below can be queried using integers:
  %
  %     - ``'run'``
  %     - ``'flip'``
  %     - ``'inv'``
  %     - ``'split'``
  %     - ``'echo'``
  %
  % It is also possible to use regular expressions in the value.
  %
  % ---
  %
  % Example 1::
  %
  %    data = bids.query(BIDS, 'data', ...
  %                            'sub', '01', ...
  %                            'task', 'stopsignalwithpseudowordnaming', ...
  %                            'run', 1:5, ...
  %                            'extension', '.nii.gz', ...
  %                            'suffix', 'bold');
  %
  %
  % Example 2::
  %
  %     filters = struct('sub', '01', ...
  %                      'task', 'stopsignalwithpseudowordnaming', ...
  %                      'run', 1:5, ...
  %                      'extension', '.nii.gz', ...
  %                      'suffix', 'bold');
  %
  %     data = bids.query(BIDS, 'data', filters);
  %
  %
  % Example 3::
  %
  %     filters = {'sub', '0[1-5]'; ...
  %                'task', 'stopsignal.*'; ...
  %                'run', 1:5; ...
  %                'extension', '.nii.*'; ...
  %                'suffix', 'bold'};
  %
  %     data = bids.query(BIDS, 'data', filters);
  %
  %
  % (C) Copyright 2016-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  %
  % (C) Copyright 2018 BIDS-MATLAB developers

  %#ok<*AGROW>
  narginchk(2, Inf);

  VALID_QUERIES = { ...
                   'sessions', ...
                   'subjects', ...
                   'modalities', ...
                   'tasks', ...
                   'runs', ...
                   'entities', ...
                   'suffixes', ...
                   'data', ...
                   'metadata', ...
                   'metafiles', ...
                   'dependencies', ...
                   'extensions', ...
                   'prefixes'};

  if ~any(strcmp(query, VALID_QUERIES))
    error('Invalid query input: ''%s''', query);
  end

  BIDS = bids.layout(BIDS);

  options = parse_query(varargin);

  % For subjects and modality we pass only the subjects/modalities asked for
  % otherwise we pass all of them

  [subjects, options] = get_subjects(BIDS, options);

  [modalities, options] = get_modalities(BIDS, options);

  % Get optional target option for metadata query
  [target, options] = get_target(query, options);

  result = perform_query(BIDS, query, options, subjects, modalities, target);

  %% Postprocessing output variable
  switch query

    case 'subjects'
      result = unique(result);
      result = regexprep(result, '^[a-zA-Z0-9]+-', '');

    case 'sessions'
      result = unique(result);
      result = regexprep(result, '^[a-zA-Z0-9]+-', '');
      result(cellfun('isempty', result)) = [];

    case {'modalities', 'data', 'metafiles'}
      result = result';

    case {'metadata', 'dependencies'}
      if numel(result) == 1
        result = result{1};
      else
        result = result';
      end

    case {'tasks', 'entities', 'runs', 'suffixes', 'extensions', 'prefixes'}
      result = unique(result);
      result(cellfun('isempty', result)) = [];
  end

end

function options = parse_query(options)

  if numel(options) == 1

    if isstruct(options{1})
      options = [fieldnames(options{1}), struct2cell(options{1})];

    elseif iscell(options{1})
      options = options{1};

    elseif isempty(options{1})
      options = cell(0, 2);
      return
    end

  else
    if mod(numel(options), 2)
      error('Invalid input syntax: each BIDS entity requires an associated label');
    end
    options = reshape(options, 2, [])';

  end

  for i = 1:size(options, 1)

    if ischar(options{i, 2})
      options{i, 2} = cellstr(options{i, 2});
    end

    if isnumeric(options{i, 2})
      options{i, 2} = {options{i, 2}};
    end

    for j = 1:numel(options{i, 2})
      if iscellstr(options{i, 2})
        options{i, 2}{j} = regexprep(options{i, 2}{j}, sprintf('^%s-', options{i, 1}), '');
      end
    end

  end

end

function [subjects, options] = get_subjects(BIDS, options)

  if any(ismember(options(:, 1), 'sub'))
    subjects = options{ismember(options(:, 1), 'sub'), 2};
    options(ismember(options(:, 1), 'sub'), :) = [];
  else
    subjects = unique({BIDS.subjects.name});
    subjects = regexprep(subjects, '^[a-zA-Z0-9]+-', '');
  end

end

function [modalities, options] = get_modalities(BIDS, options)

  if any(ismember(options(:, 1), 'modality'))
    modalities = options{ismember(options(:, 1), 'modality'), 2};

  else
    hasmod = arrayfun(@(y) structfun(@(x) isstruct(x) & ~isempty(x), y), ...
                      BIDS.subjects, 'UniformOutput', false);
    hasmod = any([hasmod{:}], 2);
    modalities   = fieldnames(BIDS.subjects)';
    modalities   = modalities(hasmod);
  end

end

function [target, options] = get_target(query, options)

  target = [];

  if strcmp(query, 'metadata') && any(ismember(options(:, 1), 'target'))

    target = options{ismember(options(:, 1), 'target'), 2};
    options(ismember(options(:, 1), 'target'), :) = [];

    if iscellstr(target)
      target = substruct('.', target{1});
    end

  end

end

function result = perform_query(BIDS, query, options, subjects, modalities, target)

  % Initialise output variable
  result = {};

  % Loop through all the subjects and modalities filtered previously
  for i = 1:numel(BIDS.subjects)

    this_subject = BIDS.subjects(i);

    % Only continue if this subject is one of those filtered
    keep = regexp(this_subject.name(5:end), subjects, 'match');
    if all(cellfun('isempty', keep))
      continue
    end

    for j = 1:numel(modalities)

      this_modality = modalities{j};

      % Only continue if this modality is one of those filtered
      if ~ismember(this_modality, fieldnames(this_subject))
        continue
      end

      result = update_result(query, options, result, this_subject, this_modality, target);

    end

  end

  result = update_result_with_root_content(query, options, result, BIDS);

end

function result = update_result(query, options, result, this_subject, this_modality, target)

  d = this_subject.(this_modality);

  for k = 1:numel(d)

    % status is kept true only if this file matches the options of the query
    d(k).modality = this_modality;
    status = bids.internal.keep_file_for_query(d(k), options);

    if status

      switch query

        case 'subjects'
          result{end + 1} = this_subject.name;

        case 'sessions'
          result{end + 1} = this_subject.session;

        case 'modalities'
          result = unique(cat(1, result, {this_modality}));

        case 'entities'
          entities = this_subject.(this_modality)(k).entities;
          fields = fieldnames(entities);
          non_empty_fields = ~structfun(@isempty, entities);
          result = unique(cat(1, result, fields(non_empty_fields)));

        case 'data'
          result{end + 1} = fullfile(this_subject.path, this_modality, d(k).filename);

        case 'metafiles'
          fmeta = this_subject.(this_modality)(k).metafile;
          result = [result; fmeta];

        case 'metadata'
          fmeta = this_subject.(this_modality)(k).metafile;
          result{end + 1, 1} = bids.internal.get_metadata(fmeta);
          if ~isempty(target)
            try
              result{end} = subsref(result{end}, target);
            catch
              warning('Non-existent field for metadata.');
              result{end} = [];
            end
          end

          % if status && isfield(d(k),'meta')
          %   result{end+1} = d(k).meta;
          % end

        case {'runs', 'tasks'}
          field = query(1:end - 1);
          if isfield(d(k).entities, field)
            result{end + 1} = d(k).entities.(field);
          end

        case {'suffixes', 'prefixes'}
          field = query(1:end - 2);
          result{end + 1} = d(k).(field);

        case 'extensions'
          result{end + 1} = d(k).ext;

        case 'dependencies'
          result{end + 1, 1} = d(k).dependencies;

      end

    end
  end
end

function result = update_result_with_root_content(query, options, result, BIDS)

  d = BIDS.root;

  % remove 'ses' key from options as it does not apply to files in the root folder
  idx = strcmp('ses', options(:, 1));
  if any(idx)
    options(idx, :) = [];
  end

  for k = 1:numel(d)

    % status is kept true only if this file matches the options of the query
    d(k).modality = '';
    status = bids.internal.keep_file_for_query(d(k), options);

    if status

      switch query

        case {'subjects', 'sessions'}

          % there should not be subject / session specific in the root folder
          % error('This should not happen!')

        case {'modalities', 'metafiles', 'dependencies', 'metadata'}

          % those cases are not covered yet

        case 'data'
          result{end + 1} = fullfile(BIDS.pth, d(k).filename);

        case {'runs', 'tasks'}
          field = query(1:end - 1);
          if isfield(d(k).entities, field)
            result{end + 1} = d(k).entities.(field);
          end

        case {'suffixes', 'prefixes'}
          field = query(1:end - 2);
          result{end + 1} = d(k).(field);

        case 'extensions'
          result{end + 1} = d(k).ext;

      end

    end
  end
end
