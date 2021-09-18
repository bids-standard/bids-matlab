function file_idx = return_file_index(BIDS, modality, filename)
  %
  % For a given filename and modality, it returns the file index
  % in the subject sub-structure of the BIDS structure
  %
  % UISAGE::
  %
  %   file_idx = return_file_index(BIDS, modality, filename)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  sub_idx = bids.internal.return_subject_index(BIDS, filename);

  file_idx = strcmp(filename, {BIDS.subjects(sub_idx).(modality).filename}');
  file_idx = find(file_idx);

end
