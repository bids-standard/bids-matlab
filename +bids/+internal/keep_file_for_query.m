function status = keep_file_for_query(file_struct, options)
  %
  % USAGE::
  %
  %   status = keep_file_for_query(file_struct, options)
  %
  %   returns ``false`` if the file is to be kept when running ``bids.query``
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  status = true;

  % prefix, suffix, extensions are treated separately
  % as they are not one of the entities
  for i = 1:size(options, 1)

    key = options{i, 1};
    if strcmp(key, 'extension')
      key = 'ext';
    end

    values = options{i, 2};

    if any(strcmp(key, {'modality', 'suffix', 'ext', 'prefix'}))

      status = check(status, file_struct, key, values);
      if status == false
        return
      end

    end

  end

  % some files in the root folder might have no entity
  if isempty(file_struct.entities)
    status = false;
    return
  end

  % work on the the entities
  for j = 1:size(options, 1)

    key = options{j, 1};

    values = options{j, 2};

    if ~any(strcmp(key, {'modality', 'suffix', 'extension', 'ext', 'prefix'}))

      status = check(status, file_struct.entities, key, values);
      if status == false
        return
      end

    end

  end

end

function  status = check(status, structure, key, values)

  % does the file have the entity or does the filename structure has this fieldname ?
  has_key = ismember(key, fieldnames(structure));
  % do we want to exclude the file (by passing an empty option) bassed on that key ?
  exclude = numel(values) == 1 && isempty(values{1});

  if ~has_key && ~exclude
    status = false;
    return
  end

  if ~has_key && exclude
    return
  end

  value = structure.(key);

  if has_key && exclude && ...
          ~isempty(value)
    status = false;
    return
  end

  if has_key && ~exclude && ...
          check_label(key, value, values)
    status = false;
    return
  end
end

function status = check_label(key, value, values)

  if ismember(key, {'run', 'flip', 'inv', 'split', 'echo'})

    if ischar(value)
      value = str2double(value);
    end

    % TODO to speed up the query this could be done only once
    % at the beginning of bids.query??
    values = convert_to_num(values);

    status = ~ismember(value, values);

  else

    status = check_label_with_regex(value, values);

  end

end

function values = convert_to_num(values)

  is_char = cellfun(@(x) ischar(x), values);

  tmp1 = values(is_char);
  tmp1 = cellfun(@(x) str2double(x), tmp1);
  tmp2 = [values{~is_char}];

  values = cat(2, tmp1, tmp2);

end

% TODO  performace issue ???
% the options could be converted to regex only once
% and not for every call to keep_file

function status = check_label_with_regex(value, option)
  if numel(option) == 1
    option = prepare_regex(option);
    keep = regexp(value, option, 'match');
    status = isempty(keep) || isempty(keep{1});
  else
    status = ~ismember(value, option);
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
