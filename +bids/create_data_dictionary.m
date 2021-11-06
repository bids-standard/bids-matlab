function create_data_dictionary(tsv_file, level_limit)
  %
  % (C) Copyright 2021 Remi Gau

  if nargin < 2
    level_limit = 10;
  end

  content = bids.util.tsvread(tsv_file);

  headers = fieldnames(content);

  json_content = struct();
  for i = 1:numel(headers)
    json_content.(headers{i}) = set_dict(headers{i});
    json_content = add_levels_description(json_content, headers{i}, content, level_limit);
  end

  bidsFile = bids.File(tsv_file, false, struct('ext', '.json'));

  filename = bidsFile.filename;
  if strcmp(bidsFile.suffix, 'participants')
    filename = strrep(filename, '_', '');
  end

  filename = fullfile(bidsFile.pth, filename);

  bids.util.jsonwrite(filename, json_content);

end

function json_content = add_levels_description(json_content, header, tsv_content, level_limit)

  levels = unique(tsv_content.(header));

  if ismember(header, {'participant_id'}) || numel(levels) > level_limit || isnumeric(levels)
    return
  end

  json_content.(header).Levels = struct();
  for i = 1:numel(levels)
    this_level = levels(i);
    if iscell(this_level)
      this_level = this_level{1};
    end
    %         if isnumeric(this_level)
    %             % add a _ because fieldnames cannot be numbers in matlab
    %             this_level = ['' num2str(this_level)];
    %         end
    json_content.(header).Levels.(this_level) = '';
  end

end

function dict = set_dict(header)

  default = struct('LongName', '', ...
                   'Description', '', ...
                   'Units', '', ...
                   'TermURL', 'https://authority.path');

  participant = struct('LongName', 'Participant Id', ...
                       'Description', 'Unique label associated with a participant');

  onset =  struct('LongName', 'Event onset time', ...
                  'Description', ...
                  'Time elapsed since experiment start when the event started', ...
                  'Units', 's');

  duration = struct( ...
                    'Description', ...
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
