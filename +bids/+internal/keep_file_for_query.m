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

    field_name = options{i, 1};
    if strcmp(field_name, 'extension')
      field_name = 'ext';
    end

    if any(strcmp(field_name, {'modality', 'suffix', 'ext', 'prefix'})) && ...
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

    if ~any(strcmp(this_entity, {'modality', 'suffix', 'extension', 'ext', 'prefix'}))

      file_has_entity = ismember(this_entity, fieldnames(file_struct.entities));
      exclude_entity = numel(label_lists) == 1 && isempty(label_lists{1});

      if ~file_has_entity && ~exclude_entity
        status = false;
        return
      end
      
      if ~file_has_entity && exclude_entity
        status = true;
        return
      end      

      this_label = file_struct.entities.(this_entity);

      if file_has_entity && exclude_entity && ...
              ~isempty(this_label)
        status = false;
        return
      end

      if file_has_entity && ~exclude_entity && ...
              check_label(this_entity, this_label, label_lists)
        status = false;
        return
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
