function data_dict = create_data_dict(varargin)
  %
  % (C) Copyright 2021 Remi Gau
  
  default_use_schema = true;
  default_output = [];
  default_verbose = true;
  default_force = false;
  default_level_limit = 10;
  
  is_file = @(x) exist(x, 'file');

  args = inputParser();

  addRequired(args, 'tsv_file', is_file);
  addParameter(args, 'level_limit', default_level_limit);
  addParameter(args, 'output', default_output);
  addParameter(args, 'schema', default_use_schema);
  addParameter(args, 'verbose', default_verbose);
  addParameter(args, 'force', default_force);

  parse(args, varargin{:});

  tsv_file = args.Results.tsv_file;
  level_limit = args.Results.level_limit;
  output = args.Results.output;
  schema = args.Results.schema;
  verbose = args.Results.verbose;
  force = args.Results.force;

  if ~iscell(tsv_file)
    tsv_file = {tsv_file};
  end
  content = bids.util.tsvread(tsv_file{1});

  headers = fieldnames(content);

  data_dict = struct();
  for i = 1:numel(headers)
    data_dict.(headers{i}) = set_dict(headers{i});
    data_dict = add_levels_description(data_dict, headers{i}, content, level_limit);
  end

  bids.util.jsonwrite(output, data_dict);

end

function json_content = add_levels_description(json_content, header, tsv_content, level_limit)

  levels = unique(tsv_content.(header));

  if ismember(header, {'participant_id'}) || ...
      numel(levels) > level_limit || ...
      not(all(isinteger(levels)))
    return
  end

  json_content.(header).Levels = struct();
  for i = 1:numel(levels)
    this_level = levels(i);
    if iscell(this_level)
      this_level = this_level{1};
    end
    if isnumeric(this_level)
      % add a _ because fieldnames cannot be numbers in matlab
      this_level = ['' num2str(this_level)];
    end
    json_content.(header).Levels.(this_level) = '';
  end

end

function dict = set_dict(header)

  default = struct('LongName', header, ...
                   'Description', 'TODO', ...
                   'Units', 'TODO', ...
                   'TermURL', 'TODO');

  participant = struct('LongName', 'Participant Id', ...
                       'Description', 'Unique label associated with a participant');

  onset =  struct('LongName', 'Event onset time', ...
                  'Description', ...
                  'Time elapsed since experiment start when the event started', ...
                  'Units', 's');

  duration = struct('Description', ...
                    'Duration of the event', ...
                    'Units', 's');

  switch header
    case 'onset'
      dict = onset;
    case 'duration'
      dict = duration;
    case 'participant_id'
      dict = participant;
    otherwise
      dict = default;
  end

end
