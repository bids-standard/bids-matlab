function pth = root_dir()
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  pth = fullfile(fileparts(mfilename('fullpath')), '..', '..');
  pth = bids.internal.file_utils(pth, 'cpath');

end
