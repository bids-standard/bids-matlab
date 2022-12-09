function pth = root_dir()
  %

  % (C) Copyright 2021 BIDS-MATLAB developers

  if bids.internal.is_octave
    warning('off', 'Octave:mixed-string-concat');
  end

  pth = fullfile(fileparts(mfilename('fullpath')), '..', '..');
  pth = bids.internal.file_utils(pth, 'cpath');

end
