function data_dict = create_data_dict(varargin)
  %
  % Create a JSON data dictionary for a TSV file.
  %
  % Levels in columns that may lead to invalid matlab structure fieldnames are
  % renamed. Hence the output may need manual cleaning.
  %
  % Descriptions may be added for columns if a match is found in the BIDS
  % schema: for example: trial_type, onset...
  %
  % To create better data dictionaries, please see the tools
  % for `hierarchical event descriptions <https://hedtools.ucsd.edu/hed/>`_.
  %
  % USAGE::
  %
  %   data_dict = bids.util.create_data_dict(tsv_file, ...
  %                                          'output', [], ...
  %                                          'schema', true, ...
  %                                          'force', false, ...
  %                                          'level_limit', 10, ...
  %                                          'verbose', true);
  %
  % :param output:          filename for the output files. Can pass be a cell
  %                         char of paths
  %
  % :param force:           If set to ``false`` it will not overwrite any file already
  %                         present in the destination.
  % :type  force:           logical
  %
  % :param schema:          If set to ``true`` it will use the schema to try to
  %                         find definitions for the column headers
  % :type  schema:          logical or a schema object
  %
  % :param level_limit:     Maximum number of levels to list. Defaults to 10;
  % :type  level_limit:
  %
  %
  % Example
  % -------
  %
  % .. code-block:: matlab
  %
  %   BIDS = bids.layout(pth_bids_example, 'ds001'));
  %
  %   tsv_files = bids.query(BIDS, 'data', ...
  %                          'sub', '01', ...
  %                          'suffix', 'events');
  %
  %   data_dict = bids.util.create_data_dict(tsv_files{1}, ...
  %                                          'output', 'tmp.json', ...
  %                                          'schema', true);
  %
  %

  % (C) Copyright 2021 Remi Gau

  default_schema = false;
  default_output = [];
  default_verbose = true;
  default_force = false;
  default_level_limit = 10;

  is_file_or_cellstr = @(x) (iscellstr(x) || exist(x, 'file'));

  args = inputParser();

  addRequired(args, 'tsv_file', is_file_or_cellstr);
  addParameter(args, 'level_limit', default_level_limit);
  addParameter(args, 'output', default_output);
  addParameter(args, 'schema', default_schema);
  addParameter(args, 'verbose', default_verbose);
  addParameter(args, 'force', default_force);

  parse(args, varargin{:});

  tsv_file = args.Results.tsv_file;
  level_limit = args.Results.level_limit;
  output = args.Results.output;
  schema = args.Results.schema;
  force = args.Results.force;
  verbose = args.Results.verbose;

  data_dict = struct();

  if ~iscell(tsv_file)
    tsv_file = {tsv_file};
  end
  if isempty(tsv_file)
    return
  end

  content = get_content_from_tsv_files(tsv_file);

  headers = fieldnames(content);

  % keep track of modified levels to print them in a TSV at the end
  modified_levels = struct('header', {{}}, ...
                           'original_level_name', {{}}, ...
                           'new_level_name', {{}});

  for i = 1:numel(headers)
    if strcmp(bids.internal.file_utils(tsv_file{1}, ...
                                       'basename'), ...
              'participants') && ...
        strcmp(headers{i}, 'participant_id')
      continue
    end
    data_dict.(headers{i}) = set_dict(headers{i}, schema);
    [data_dict, modified_levels] = add_levels_desc(data_dict, ...
                                                   headers{i}, ...
                                                   content, ...
                                                   level_limit, ...
                                                   modified_levels, ...
                                                   verbose);
  end

  if isempty(output)
    return
  end

  if ~exist(output, 'file') || force

    bids.util.jsonwrite(output, data_dict);

    if ~isempty(modified_levels.header)
      bids.util.tsvwrite(fullfile(fileparts(output), 'modified_levels.tsv'), ...
                         modified_levels);
    end

  end

end

function content = get_content_from_tsv_files(tsv_file)

  content = bids.util.tsvread(tsv_file{1});

  % if there is more than one TSV file,
  % the content of all files is concatenated together
  % to create a single data dictionary across TSVfiles.
  if numel(tsv_file) > 1

    for f = 2:numel(tsv_file)

      new_content = bids.util.tsvread(tsv_file{f});
      [content, new_content] = bids.internal.match_structure_fields(content, new_content);

      headers = fieldnames(content);

      for h = 1:numel(headers)

        append_to = content.(headers{h});
        to_append = new_content.(headers{h});

        if isempty(append_to)
          append_to = nan;
        end

        if isempty(to_append)
          to_append = nan;
        end

        % dealing with nan
        if iscellstr(append_to) && ~iscellstr(to_append)
          if all(isnan(to_append))
            to_append = repmat({'n/a'}, numel(to_append), 1);
          end
        end

        if iscellstr(to_append) && ~iscellstr(append_to)
          if all(isnan(append_to))
            append_to = repmat({'n/a'}, numel(append_to), 1);
          end
        end

        content.(headers{h}) = cat(1, append_to, to_append);

        % ???
        if (ischar(content.(headers{h})) || iscellstr(content.(headers{h}))) && ...
            any(strcmp(content.(headers{h}), ' '))
        end

      end

    end

  end

end

function [json, modified] = add_levels_desc(json, hdr, tsv, lvl_limit, modified, verbose)

  levels = unique(tsv.(hdr));

  % we do not list non integer numeric values
  % as this is most likely not categorical
  if numel(levels) > lvl_limit || ...
     (isnumeric(levels) && not(all(isinteger(levels))))
    return
  end

  json.(hdr).Levels = struct();

  for i = 1:numel(levels)

    this_level = levels(i);

    if iscell(this_level)
      this_level = this_level{1};
    end

    if strcmp(this_level, 'n/a')
      continue
    end

    level_name_before = this_level;

    % assume that numeric values (should be integers) are dummy coding for
    % something categorical
    % if not the user will have some clean up to do manually
    if isnumeric(this_level)
      % add a prefix because fieldnames cannot be numbers in matlab
      this_level = ['level_' num2str(this_level)];
    end

    % remove any illegal character to turn it into a valid structure fieldname
    this_level = regexprep(this_level, '[^a-zA-Z0-9]', '_');

    pre = regexprep(this_level(1), '[0-9_]', ['level_' this_level(1)]);
    if numel(this_level) > 1
      this_level = [pre this_level(2:end)];
    else
      this_level = pre;
    end

    if strcmp(this_level, '_')
      bids.internal.error_handling(mfilename(), 'skippingLevel', ...
                                   sprintf('\nSkipping level %s.', level_name_before), ...
                                   true, ...
                                   verbose);
      continue
    end

    if ~strcmp(level_name_before, this_level)
      modified.header{end + 1} = hdr;
      modified.original_level_name{end + 1} = level_name_before;
      modified.new_level_name{end + 1} = this_level;
      warning_modified_level_name(level_name_before, hdr, this_level, verbose);
    end

    json.(hdr).Levels.(this_level) = struct('Description', level_name_before, ...
                                            'TermURL', 'TODO');

  end

end

function warning_modified_level_name(level, header, new_name, verbose)

  tolerant = true;

  msg = sprintf(['Level "%s" of column "%s" modified to "%s".\n', ...
                 'Check the HED tools to help you create better data dictionaries: %s.\n'], ...
                level, header, new_name, ...
                'https://hedtools.ucsd.edu/hed/');

  bids.internal.error_handling(mfilename(), 'modifiedLevel', msg, tolerant, verbose);
end

function dict = set_dict(header, schema)
  %
  % get default description from the schema
  %

  dict = default_dict(header);

  if (isobject(schema) && isfield(schema.content, 'objects')) || schema == true

    try
      [def, status] = schema.get_definition(header);
    catch
      schema = bids.Schema();
      [def, status] = schema.get_definition(header);
    end

    if ~status
      return
    end

    dict.LongName = def.name;
    dict.Description = def.description;

    if isfield(def, 'unit')
      dict.Units = def.unit;
    elseif isfield(def, 'anyOf')
      if iscell(def.anyOf)
        number_allowed = cellfun(@(x) strcmp(x.type, 'number'), def.anyOf);
        if any(number_allowed) && isfield(def.anyOf, 'unit')
          dict.Units = def.anyOf{number_allowed}.unit;
        end
      end
    end

  end

end

function default = default_dict(header)

  default = struct('LongName', header, ...
                   'Description', 'TODO', ...
                   'Units', 'TODO', ...
                   'TermURL', 'TODO');

end
