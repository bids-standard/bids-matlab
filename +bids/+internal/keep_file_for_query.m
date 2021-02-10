function status = keep_file(file_struct, options)

  status = true;

  % suffix is treated separately as it is not one of the entities
  for l = 1:size(options, 1)
    if strcmp(options{l, 1}, 'suffix') && ~ismember(file_struct.suffix, options{l, 2})
      status = false;
      return
    end
  end

  for l = 1:size(options, 1)

    if ~strcmp(options{l, 1}, 'suffix')

      if ~ismember(options{l, 1}, fieldnames(file_struct.entities))
        status = false;
        break
      end

      if isfield(file_struct.entities, options{l, 1}) && ...
              ~ismember(file_struct.entities.(options{l, 1}), options{l, 2})
        status = false;
        break
      end

    end

  end

end
