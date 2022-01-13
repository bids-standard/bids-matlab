function pth = root_dir()
  %
  % (C) Copyright 2021 BIDS-MATLAB developers
  persistent pth;
  if isempty(pth)
    pth = fullfile(fileparts(mfilename('fullpath')), '..', '..');
    pth = bids.internal.file_utils(fullfile(fileparts(mfilename('fullpath')), '..', '..'), 'cpath');
  end

end
