function data_dict = create_data_dict(varargin)
  %
  % Create a data dictionnary for a TSV file
  %
  % data_dict = bids.util.create_data_dict(tsv_file, ...
  %                                        'output', [], ...
  %                                        'schema', true, ...
  %                                        'force', false, ...
  %                                        'level_limit', 10);
  %
  %
  % :param output:           filename for the output file
  %
  % :param force:           If set to ``false`` it will not overwrite any file already
  %                         present in the destination.
  % :type  force:           boolean
  %
  % :param schema:          If set to ``true`` it will use the schema to try to
  %                         find definitions for the column headers
  % :type  schema:          boolean or a schema object
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

  for i = 1:numel(headers)
    data_dict.(headers{i}) = set_dict(headers{i}, schema);
    data_dict = add_levels_description(data_dict, headers{i}, content, level_limit);
  end

  if ~isempty(output)
    if exist(output, 'file')
      if force
        bids.util.jsonwrite(output, data_dict);
      end
    else
      bids.util.jsonwrite(output, data_dict);
    end
  end

end

function content = get_content_from_tsv_files(tsv_file)

  content = bids.util.tsvread(tsv_file{1});

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

        if (ischar(content.(headers{h})) || iscellstr(content.(headers{h}))) && ...
            any(strcmp(content.(headers{h}), ' '))
        end

      end

    end

  end

end

function json_content = add_levels_description(json_content, header, tsv_content, level_limit)

  levels = unique(tsv_content.(header));

  if numel(levels) > level_limit || ...
     (isnumeric(levels) && not(all(isinteger(levels))))
    return
  end

  json_content.(header).Levels = struct();

  for i = 1:numel(levels)

    this_level = levels(i);

    if iscell(this_level)
      this_level = this_level{1};
    end

    if isnumeric(this_level)
      % add a prefix because fieldnames cannot be numbers in matlab
      this_level = ['level_' num2str(this_level)];
    end

    this_level = regexprep(this_level, '[^a-zA-Z0-9]', '_');

    pre = regexprep(this_level(1), '[0-9_]', ['level_' this_level(1)]);
    if numel(this_level) > 1
      this_level = [pre this_level(2:end)];
    else
      this_level = pre;
    end

    if strcmp(this_level, '_')
      continue
    end

    json_content.(header).Levels.(this_level) = 'TODO';

  end

end

function dict = set_dict(header, schema)

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
        if any(number_allowed)
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
