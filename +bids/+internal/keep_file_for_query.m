function status = keep_file_for_query(file_struct, options)
  %
  % USAGE::
  %
  %   status = keep_file_for_query(file_struct, options)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  status = true;

  % prefix, suffix, extensions are treated separately
  % as they are not one of the entities
  for i = 1:size(options, 1)

    field_name = options{i, 1};
    if strcmp(field_name, 'extension')
      field_name = 'ext';
    end

    if any(strcmp(field_name, {'suffix', 'ext', 'prefix'})) && ...
             check_label_with_regex(file_struct.(field_name), options{i, 2})
      status = false;
      return
    end

  end

  % some files in the root folder might have no entity
  if isempty(file_struct.entities)
    status = false;
    return
  end

  % work on the the entities
  for j = 1:size(options, 1)

    this_entity = options{j, 1};
    label_lists = options{j, 2};

    if ~any(strcmp(this_entity, {'suffix', 'extension', 'ext', 'prefix'}))

      file_has_entity = ismember(this_entity, fieldnames(file_struct.entities));
      exclude_entity = numel(label_lists) == 1 && isempty(label_lists{1});

      if ~file_has_entity && ~exclude_entity
        status = false;
        break
      end

      this_label = file_struct.entities.(this_entity);

      if file_has_entity && ~exclude_entity && ...
              check_label(this_entity, this_label, label_lists)
        status = false;
        break
      end

      if file_has_entity && exclude_entity && ...
              ~isempty(this_label)
        status = false;
        break
      end

    end

  end

end

function status = check_label(this_entity, label, label_lists)

  if ismember(this_entity, {'run', 'flip', 'inv', 'split', 'echo'})

    if ischar(label)
      label = str2double(label);
    end

    % TODO to speed up the query this could be done only once
    % at the beginning of bids.query??
    label_lists = convert_to_num(label_lists);

    status = ~ismember(label, label_lists);

  else

    status = check_label_with_regex(label, label_lists);

  end

end

function label_lists = convert_to_num(label_lists)

  is_char = cellfun(@(x) ischar(x), label_lists);

  tmp1 = label_lists(is_char);
  tmp1 = cellfun(@(x) str2double(x), tmp1);
  tmp2 = [label_lists{~is_char}];

  label_lists = cat(2, tmp1, tmp2);

end

function status = check_label_with_regex(label, option)
  if numel(option) == 1
    keep = regexp(label, option, 'match');
    status = isempty(keep{1});
  else
    status = ~ismember(label, option);
  end
end
