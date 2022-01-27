function file_info = return_file_info(BIDS, fullpath_filename)
  %
  % USAGE::
  %
  %   file_info = return_file_info(BIDS, fullpath_filename)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  file_info.path = bids.internal.file_utils(fullpath_filename, 'path');
  file_info.filename = bids.internal.file_utils(fullpath_filename, 'filename');

  file_info.sub_idx = bids.internal.return_subject_index(BIDS, file_info.filename);
  % for files in the root folder with no sub entity we return early
  if isempty(file_info.sub_idx)
    return
  end

  file_info.modality = bids.internal.file_utils(file_info.path, 'filename');
  file_info.file_idx = bids.internal.return_file_index(BIDS, ...
                                                       file_info.modality, ...
                                                       file_info.filename);

end
