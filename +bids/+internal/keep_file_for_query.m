function status = keep_file_for_query(file_struct, options)
  %
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  status = true;

  % suffix and extensions are treated separately
  % as they are not one of the entities
  for l = 1:size(options, 1)
    if strcmp(options{l, 1}, 'suffix') && ~ismember(file_struct.suffix, options{l, 2})
      status = false;
      return
    end
    if strcmp(options{l, 1}, 'extension') && ~ismember(file_struct.ext, options{l, 2})
      status = false;
      return
    end
    if strcmp(options{l, 1}, 'prefix') && ~ismember(file_struct.prefix, options{l, 2})
      status = false;
      return
    end
  end

  for l = 1:size(options, 1)

    if ~any(strcmp(options{l, 1}, {'suffix', 'extension', 'prefix'}))
        
      file_has_entity = ismember(options{l, 1}, fieldnames(file_struct.entities));
      exclude_entity = numel(options{l, 2}) == 1 && strcmp(options{l, 2}, {''});
 
      if ~file_has_entity && ~exclude_entity
        status = false;
        break
      end
      
      if file_has_entity && exclude_entity && ~isempty(file_struct.entities.(options{l, 1}))
        status = false;
        break
      end

      if file_has_entity && ~exclude_entity && ...
              ~ismember(file_struct.entities.(options{l, 1}), options{l, 2})
        status = false;
        break
      end

    end

  end

end
