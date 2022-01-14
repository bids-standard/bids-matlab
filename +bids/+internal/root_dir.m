function pth = root_dir()
  %
  % (C) Copyright 2021 BIDS-MATLAB developers
  persistent path;
  if isempty(path)
    path = fullfile(fileparts(mfilename('fullpath')), '..', '..');
    path = bids.internal.file_utils(fullfile(fileparts(mfilename('fullpath')), '..', '..'), 'cpath');
  end
  pth = path;

end
