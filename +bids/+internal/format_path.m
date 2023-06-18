function pth = format_path(pth)
  %
  % USAGE::
  %
  %   pth = bids.internal.format_path(pth)
  %
  % Replaces single '\' by '/' in Windows paths
  % to prevent escaping warning when printing a path to screen
  %
  % :param pth: If pth is a cellstr of paths, pathToPrint will work
  %             recursively on it.
  % :type pth: char or cellstr$
  %
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  if isunix()
    return
  end

  if ischar(pth)
    pth = strrep(pth, '\', '\\');

  elseif iscell(pth)
    for i = 1:numel(pth)
      pth{i} = strrep(pth{i}, '\', '\\');
    end
  end

end
