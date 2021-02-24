function result = query(BIDS, query, varargin)
  %
  % Queries a directory structure formatted according to the BIDS standard
  %
  % USAGE::
  %
  %   result = bids.query(BIDS, query, ...)
  %
  % :param BIDS: BIDS directory name or BIDS structure (from bids.layout)
  % :type  BIDS: (strcuture or string)
  % :param query: type of query:
  %                          - 'data',
  %                          - 'metadata',
  %                          - 'sessions',
  %                          - 'subjects',
  %                          - 'runs',
  %                          - 'tasks',
  %                          - 'suffixes',
  %                          - 'modalities'
  % :type  query: string
  %
  %

  % __________________________________________________________________________
  %
  % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
  %   The brain imaging data structure, a format for organizing and
  %   describing outputs of neuroimaging experiments.
  %   K. J. Gorgolewski et al, Scientific Data, 2016.
  % __________________________________________________________________________

  % Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  %#ok<*AGROW>
  narginchk(2, Inf);

  VALID_QUERIES = { ...
                   'sessions', ...
                   'subjects', ...
                   'modalities', ...
                   'tasks', ...
                   'runs', ...
                   'suffixes', ...
                   'data', ...
                   'metadata', ...
                   'metafiles',...
                   'dependencies', ...
                   'extensions'};

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

    case {'tasks', 'runs', 'suffixes', 'extensions'}
      result = unique(result);
      result(cellfun('isempty', result)) = [];
  end

end

function options = parse_query(options)

  if numel(options) == 1 && isstruct(options{1})
    options = [fieldnames(options{1}), struct2cell(options{1})];

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
    options(ismember(options(:, 1), 'modality'), :) = [];
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

    % Only continue if this subject is one of those filtered
    if ~ismember(BIDS.subjects(i).name(5:end), subjects)
      continue
    end

    for j = 1:numel(modalities)

      % Only continue if this modality is one of those filtered
      if ~ismember(modalities{j}, fieldnames(BIDS.subjects(i)))
        continue
      end

      d = BIDS.subjects(i).(modalities{j});

      for k = 1:numel(d)

        % status is kept true only if this file matches
        % the options of the query
        status = bids.internal.keep_file_for_query(d(k), options);

        if status

          switch query

            case 'subjects'
              result{end + 1} = BIDS.subjects(i).name;

            case 'sessions'
              result{end + 1} = BIDS.subjects(i).session;

            case 'modalities'
              hasmod = structfun(@(x) isstruct(x) & ~isempty(x), ...
                                 BIDS.subjects(i));
              allmods = fieldnames(BIDS.subjects(i))';
              result = union(result, allmods(hasmod));

            case 'data'
              if isfield(d(k), 'filename')
                result{end + 1} = fullfile(BIDS.subjects(i).path, modalities{j}, d(k).filename);
              end

            case 'metafiles'
              if isfield(d(k), 'filename')
                fmeta = BIDS.subjects(i).(modalities{j})(k).metafile;
                result = [result; fmeta];
              end

            case 'metadata'
              if isfield(d(k), 'filename')
                fmeta = BIDS.subjects(i).(modalities{j})(k).metafile;
                result{end + 1, 1} = bids.internal.get_metadata(fmeta);
                if ~isempty(target)
                  try
                    result{end} = subsref(result{end}, target);
                  catch
                    warning('Non-existent field for metadata.');
                    result{end} = [];
                  end
                end

              end
              % if status && isfield(d(k),'meta')
              %   result{end+1} = d(k).meta;
              % end

            case 'runs'
              if isfield(d(k).entities, 'run')
                result{end + 1} = d(k).entities.run;
              end

            case 'tasks'
              if isfield(d(k).entities, 'task')
                result{end + 1} = d(k).entities.task;
              end

            case 'suffixes'
              if isfield(d(k), 'suffix')
                result{end + 1} = d(k).suffix;
              end

            case 'extensions'
              if isfield(d(k), 'ext')
                result{end + 1} = d(k).ext;
              end

            case 'dependencies'
              if isfield(d(k), 'dependencies')
                result{end + 1, 1} = d(k).dependencies;
              end

          end

        end
      end
    end
  end

end
