function result = query(BIDS, query, varargin)
  %
  % Queries a directory structure formatted according to the BIDS standard
  %
  % USAGE::
  %
  %   result = bids.query(BIDS, query, filter)
  %
  % :param BIDS: BIDS directory name or BIDS structure (from bids.layout)
  % :type  BIDS: strcuture or string
  %
  % :param query: type of query (see list below)
  % :type  query: string
  %
  % Type of query allowed.
  %
  % Any of the following:
  %
  % - ``'modalities'``
  % - ``'entities'``
  % - ``'suffixes'``
  % - ``'data'``
  % - ``'metadata'``
  % - ``'metafiles'``
  % - ``'dependencies'``
  % - ``'extensions'``
  % - ``'prefixes'``
  %
  % And any of the BIDS entities:
  %
  % - ``'acquisitions'``
  % - ``'atlases'``
  % - ``'ceagents'``
  % - ``'chunks'``
  % - ``'densities'``
  % - ``'descriptions'``
  % - ``'directions'``
  % - ``'echos'``
  % - ``'flips'``
  % - ``'hemispheres'``
  % - ``'inversions'``
  % - ``'labels'``
  % - ``'mtransfers'``
  % - ``'parts'``
  % - ``'processings'``
  % - ``'reconstructions'``
  % - ``'recordings'``
  % - ``'resolutions'``
  % - ``'sessions'``
  % - ``'subjects'``
  % - ``'runs'``
  % - ``'samples'``
  % - ``'spaces'``
  % - ``'splits'``
  % - ``'stains'``
  % - ``'tasks'``
  % - ``'tracers'``
  %
  % .. warning::
  %
  %   Note that all the query types are plurals.
  %
  % :param filter: filter for the query
  % :type  filter: structure, nX2 cell, series of key-value parameters
  %
  % The choice of available keys to filter with includes:
  %
  % - ``'suffix'``
  % - ``'extension'``
  % - ``'prefix'``
  % - ``'modality'``
  %
  % It can also include any of the entity keys present in the files in the dataset.
  % To know what those are, use::
  %
  %   bids.query(BIDS, 'entities')
  %
  % .. warning::
  %
  %   Note that integers as query label for the entity keys listed below:
  %
  %     - ``'run'``
  %     - ``'flip'``
  %     - ``'inv'``
  %     - ``'split'``
  %     - ``'echo'``
  %     - ``'chunk'``
  %
  % It is also possible to use regular expressions in the value.
  %
  % Regex example::
  %
  %     % The following 2 will return the same thing
  %     data = bids.query(BIDS, 'data', 'sub', '01')
  %     data = bids.query(BIDS, 'data', 'sub', '^01$')
  %
  %     % But the following would return all the data for all subjects
  %     % whose label ends in '01'
  %     data = bids.query(BIDS, 'data', 'sub', '.*01')
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

  VALID_QUERIES = cat(2, {'sessions', ...
                          'subjects', ...
                          'modalities', ...
                          'entities', ...
                          'suffixes', ...
                          'data', ...
                          'metadata', ...
                          'metafiles', ...
                          'dependencies', ...
                          'extensions', ...
                          'prefixes'}, ...
                      valid_entity_queries());

  if ~any(strcmp(query, VALID_QUERIES))
    msg = sprintf('\nInvalid query input: ''%s''.\n\nValid queries are:\n- %s', ...
                  query, ...
                  strjoin(VALID_QUERIES, '\n- '));
    bids.internal.error_handling(mfilename(), 'unknownQuery', msg, false, true);
  end

  bids_entities = schema_entities();

  BIDS = bids.layout(BIDS);

  options = parse_query(varargin);

  % For subjects and modality we pass only the subjects/modalities asked for
  % otherwise we pass all of them

  [subjects, options] = get_subjects(BIDS, options);

  [modalities, options] = get_modalities(BIDS, options);

  % Get optional target option for metadata query
  [target, options] = get_target(query, options);

  result = perform_query(BIDS, query, options, subjects, modalities, target, bids_entities);

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

    case cat(2, {'suffixes',  'suffixes', 'extensions', 'prefixes'}, valid_entity_queries())
      result = unique(result);
      result(cellfun('isempty', result)) = [];
  end

end

function value = valid_entity_queries()

  % sessions and subjets are not included below because they are treated differently in the code
  value = cat(2, short_valid_entity_queries(), long_valid_entity_queries());

end

function value = short_valid_entity_queries()
  %
  % list the entities whose key can be obtained by removing the final "s"
  %

  value = { ...
           'chunks', ...
           'echos', ...
           'flips', ...
           'labels', ...
           'parts', ...
           'runs', ...
           'samples', ...
           'spaces', ...
           'splits', ...
           'stains', ...
           'tasks', ...
           'tracers'};
end

function value = long_valid_entity_queries()
  %
  % list the entities whose key CANNOT be obtained by removing the final "s"
  %

  value = { ...
           'acquisitions', ...
           'atlases', ...
           'ceagents', ...
           'densities', ...
           'descriptions', ...
           'directions', ...
           'hemispheres', ...
           'inversions', ......
           'mtransfers', ...
           'processings', ...
           'reconstructions', ...
           'recordings', ...
           'resolutions'};
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

function result = perform_query(BIDS, query, options, subjects, modalities, target, bids_entities)

  % Initialise output variable
  result = {};

  % Loop through all the subjects and modalities filtered previously
  for i = 1:numel(BIDS.subjects)

    this_subject = BIDS.subjects(i);

    % Only continue if this subject is one of those filtered
    if check_label_with_regex(this_subject.name(5:end), subjects)
      continue
    end

    for j = 1:numel(modalities)

      this_modality = modalities{j};

      % Only continue if this modality is one of those filtered
      if ~ismember(this_modality, fieldnames(this_subject))
        continue
      end

      result = update_result(query, options, result, this_subject, ...
                             this_modality, target, bids_entities);

    end

  end

  result = update_result_with_root_content(query, options, result, BIDS, bids_entities);

end

function result = update_result(varargin)
  %
  % result = update_result(query,options,result,this_subject,this_modality,target,bids_entities)
  %

  query = varargin{1};
  options = varargin{2};
  result = varargin{3};
  this_subject = varargin{4};
  this_modality = varargin{5};
  target = varargin{6};
  bids_entities = varargin{7};

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

        case valid_entity_queries()

          result = update_if_entity(query, result, d(k), bids_entities);

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

function result = update_result_with_root_content(query, options, result, BIDS, bids_entities)

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

        case valid_entity_queries()

          result = update_if_entity(query, result, d(k), bids_entities);

        case {'suffixes', 'prefixes'}
          field = query(1:end - 2);
          result{end + 1} = d(k).(field);

        case 'extensions'
          result{end + 1} = d(k).ext;

      end

    end
  end
end

function value = schema_entities()
  schema = bids.Schema;
  value = schema.content.objects.entities;
end

function result = update_if_entity(query, result, dk, bids_entities)

  if ismember(query, short_valid_entity_queries())
    field = query(1:end - 1);

  elseif  ismember(query, {'atlases'})
    field =  'atlas';

  elseif ismember(query, long_valid_entity_queries())
    field =  bids_entities.(query(1:end - 1)).entity;

  else
    error('query ''%s'' not yet implemented', query);

  end

  if isfield(dk.entities, field)
    result{end + 1} = dk.entities.(field);
  end

end

% TODO  performace issue ???
% the options could be converted to regex only once
% and not for every call to keep_file

function status = check_label_with_regex(label, option)
  if numel(option) == 1
    option = prepare_regex(option);
    keep = regexp(label, option, 'match');
    status = isempty(keep) || isempty(keep{1});
  else
    status = ~ismember(label, option);
  end
end

function option = prepare_regex(option)
  option = option{1};
  if strcmp(option, '')
    return
  end
  if ~strcmp(option(1), '^')
    option = ['^' option];
  end
  if ~strcmp(option(end), '$')
    option = [option '$'];
  end
end
