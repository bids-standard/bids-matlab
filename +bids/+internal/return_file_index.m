function file_idx = return_file_index(BIDS, modality, filename)

  % Copyright (C) 2018--, BIDS-MATLAB developers

  sub_idx = bids.internal.return_subject_index(BIDS, filename);

  file_idx = strcmp(filename, {BIDS.subjects(sub_idx).(modality).filename}');
  file_idx = find(file_idx);

end
