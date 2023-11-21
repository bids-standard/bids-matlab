function result = query(BIDS, query, varargin)
  %
  % Queries a directory structure formatted according to the BIDS standard
  %
  % USAGE::
  %
  %   result = bids.query(BIDS, query, filter)
  %
  % :param BIDS: BIDS directory name or BIDS structure (from bids.layout)
  % :type  BIDS: structure or char
  %
  % :param query: type of query (see list below)
  % :type  query: char
  %
  % Type of queries allowed.
  %
  % Any of the following:
  %
  % - ``'modalities'``: known as datatype in BIDS (anat, func, eeg...)
  % - ``'entities'``
  % - ``'suffixes'``
  % - ``'data'``: filenames
  % - ``'metadata'``: associated metadata (using the inheriance principle)
  % - ``'metafiles'``: json sidecar files
  % - ``'dependencies'``: associated files (for example the event.tsv for a bold.nii
  %   or eeg.eeg file)
  % - ``'participants'``: content and metadata of participants.tsv
  % - ``'phenotype'``: content and metadata of the phenotype folder
  % - ``'extensions'``
  % - ``'tsv_content'``
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
  %   Note that most of the query types are plurals.
  %
  % :param filter: filter for the query
  % :type  filter: structure or nX2 cell or series of key-value parameters
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
  % If you want to exclude an entity, use ``''`` or ``[]``.
  %
  % It is possible to use regular expressions in the queried values.
  %
  % Examples
  % --------
  %
  % Querying for 'BOLD' files for subject '01', for run 1 to 5
  % of the 'stopsignalwithpseudowordnaming' task
  % with gunzipped nifti files.
  %
  % .. code-block:: matlab
  %
  %    data = bids.query(BIDS, 'data', ...
  %                            'sub', '01', ...
  %                            'task', 'stopsignalwithpseudowordnaming', ...
  %                            'run', 1:5, ...
  %                            'extension', '.nii.gz', ...
  %                            'suffix', 'bold');
  %
  % Same as above but using a filter structure.
  %
  % .. code-block:: matlab
  %
  %     filters = struct('sub', '01', ...
  %                      'task', 'stopsignalwithpseudowordnaming', ...
  %                      'run', 1:5, ...
  %                      'extension', '.nii.gz', ...
  %                      'suffix', 'bold');
  %
  %     data = bids.query(BIDS, 'data', filters);
  %
  % Same as above but using regular expression
  % to query for subjects 1 to 5.
  %
  % .. code-block:: matlab
  %
  %     filters = {'sub', '0[1-5]'; ...
  %                'task', 'stopsignal.*'; ...
  %                'run', 1:5; ...
  %                'extension', '.nii.*'; ...
  %                'suffix', 'bold'};
  %
  %     data = bids.query(BIDS, 'data', filters);
  %
  % The following query would return all files that do not contain the
  % task entity.
  %
  % .. code-block:: matlab
  %
  %     data = bids.query(BIDS, 'data', 'task', '')
  %

  % (C) Copyright 2016-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging
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
                          'participants', ...
                          'phenotype', ...
                          'extensions', ...
                          'prefixes', ...
                          'tsv_content'}, ...
                      valid_entity_queries());

  if ~any(strcmp(query, VALID_QUERIES))
    msg = sprintf('\nInvalid query input: ''%s''.\n\nValid queries are:\n- %s', ...
                  query, ...
                  strjoin(VALID_QUERIES, '\n- '));
    bids.internal.error_handling(mfilename(), 'unknownQuery', msg, false, true);
  end

  BIDS = bids.layout(BIDS);

  if ismember(query, {'participants', 'phenotype'})
    result = BIDS.(query);
    return
  end

  options = parse_query(varargin);

  % For subjects and modality we pass only the subjects/modalities asked for
  % otherwise we pass all of them

  [subjects, options] = get_subjects(BIDS, options);
  if isempty(subjects) || any(cellfun('isempty', subjects))
    result = {};
    msg = sprintf(['Queries with "sub, ''''" or "sub, []" will return empty, ', ...
                   '\nas they exclude all subjects from the query.']);
    bids.internal.error_handling(mfilename(), 'emptySubjectFilter', msg, true, true);
    return
  end

  [modalities, options] = get_modalities(BIDS, options);

  % Get optional target option for metadata query
  [target, options] = get_target(query, options);

  if strcmp(query, 'tsv_content')
    result = perform_query(BIDS, 'data', options, subjects, modalities, target);
  else
    result = perform_query(BIDS, query, options, subjects, modalities, target);
  end

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

    case 'tsv_content'
      if isempty(result)
        return
      end
      extensions = bids.internal.file_utils(result, 'ext');
      if numel(unique(extensions)) > 1 || ~strcmp(unique(extensions), 'tsv')
        result = bids.internal.format_path(result);
        msg = sprintf(['Queries for ''tsv_content'' must be done only on tsv files.\n', ...
                       'Your query returned: %s'], ...
                      bids.internal.create_unordered_list(result));
        bids.internal.error_handling(mfilename(), 'notJustTsvFiles', msg, false);
        return
      end
      tmp = {};
      for i_tsv_file = 1:numel(result)
        tmp{i_tsv_file} = bids.util.tsvread(result{i_tsv_file});
      end
      result = tmp;

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
    if ~isfield(BIDS, 'subjects') || ~isfield(BIDS.subjects, 'name')
      msg = sprintf(['No subject present in dataset:\n\t%s.', ...
                     '\nDid you run bids.layout first?'], ...
                    bids.internal.format_path(BIDS.pth));
      bids.internal.error_handling(mfilename(), 'noSubjectField', msg, false);
    end
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
                             this_modality, target);

    end

    result = update_result_scans_sessions_tsv(query, result, this_subject, options);

  end

  result = update_result_with_root_content(query, options, result, BIDS);

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
              msg = sprintf('Non-existent field "%s" for metadata.', target.subs);
              bids.internal.error_handling(mfilename(), ...
                                           'unknownMetadata', ...
                                           msg, ...
                                           true);
              result{end} = [];
            end
          end

          % if status && isfield(d(k),'meta')
          %   result{end+1} = d(k).meta;
          % end

        case valid_entity_queries()

          result = update_if_entity(query, result, d(k));

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

function result = update_result_scans_sessions_tsv(query, result, this_subject, options)
  %
  % add scans.tsv and sessions.tsv to results list:
  % - if user asked for data
  % - filter by entities
  %

  if strcmp(query, 'data')

    bf = bids.File(this_subject.scans);
    status = bids.internal.keep_file_for_query(bf, options);
    if status
      result{end + 1} = this_subject.scans;
    end

    bf = bids.File(this_subject.sess);
    status = bids.internal.keep_file_for_query(bf, options);
    if status
      result{end + 1} = this_subject.sess;
      result = unique(result);
    end

  end

  if strcmp(query, 'suffixes')
    if ~isempty(this_subject.scans)
      bf = bids.File(this_subject.scans);
      status = bids.internal.keep_file_for_query(bf, options);
      if status
        result{end + 1} = 'scans';
      end
    end
    if ~isempty(this_subject.sess)
      bf = bids.File(this_subject.sess);
      status = bids.internal.keep_file_for_query(bf, options);
      if status
        result{end + 1} = 'sessions';
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

        case valid_entity_queries()

          result = update_if_entity(query, result, d(k));

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

function result = update_if_entity(query, result, dk)

  if ismember(query, short_valid_entity_queries())
    field = query(1:end - 1);

  elseif  ismember(query, {'atlases'})
    field =  'atlas';

  elseif ismember(query, long_valid_entity_queries())

    bids_entities = schema_entities();
    field =  bids_entities.(query(1:end - 1)).name;

  else
    error('query ''%s'' not yet implemented', query);

  end

  if isfield(dk.entities, field)
    result{end + 1} = dk.entities.(field);
  end

end

% TODO  performance issue ???
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
