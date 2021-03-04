function check_data_consistency(to_check, varargin)
  %
  % Given a set of filepaths cellarrays from bids.query, checks that any
  % all paths at same index have consistent bids name and same size
  % Raise error if inconsistency found
  %
  % Options:
  %   allow_duplicates  -- if set, will allow duplicated filenames
  %   same_suffix -- if set, files must have same suffix
  %   same_extention -- if set, files must have same extention
  %
  % USAGE::
  %
  %   bids.util.check_data_consistency([data1, data2, data3])
  %
  %
  % __________________________________________________________________________
  %
  % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
  %   The brain imaging data structure, a format for organizing and
  %   describing outputs of neuroimaging experiments.
  %   K. J. Gorgolewski et al, Scientific Data, 2016.
  % __________________________________________________________________________
  %
  % Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  %% Validate input arguments
  % ==========================================================================

  allow_duplicates = false;
  same_suffix = false;
  same_extention = false;

  if isempty(to_check)
    error('No data selected');
  end

  for ii = 1:size(varargin, 1)
    if strcmp(varargin{ii}, 'allow_duplicates')
      allow_duplicates = true;
    elseif strcmp(varargin{ii}, 'same_suffix')
      same_suffix = true;
    elseif strcmp(varargin{ii}, 'same_extention')
      same_extention = true;
    else 
      error(['Unrecognised option ' varargin{ii}]);
    end
  end

  for iFile = 1:size(to_check, 1)
    [pth, f1, ext] = fileparts(to_check{iFile, 1});

    % ugly but needed in case of compressed files (double extentions)
    [f1, ext1] = split_extention(f1);
    ext1 = [ext1, ext];
    [base1, suffix1] = split_suffix(f1);
    
    for iData = 2:size(to_check, 2)
      [pth, f2, ext] = fileparts(to_check{iFile, iData});
      [f2, ext2] = split_extention(f2);
      ext2 = [ext2, ext];
      [base2, suffix2] = split_suffix(f2);

      if ~allow_duplicates
        if strcmp(f1, f2) && strcmp(ext1, ext2)
          msg = sprintf('File %s (%d, %d) duplicates file %s (%d, %d)',...
                        f1, iFile, 1,...
                        f2, iFile, iData);
          error(msg);
        end
      end

      if ~strcmp(base1, base2)
        msg = sprintf('File %s (%d, %d) mismatch file %s (%d, %d)',...
                      f1, iFile, 1,...
                      f2, iFile, iData);
        error(msg);
      end

      if same_suffix && ~strcmp(suffix1, suffix2)
        msg = sprintf('File %s (%d, %d) mismatch suffix file %s (%d, %d)',...
                      f1, iFile, 1,...
                      f2, iFile, iData);
        error(msg);
      end

      if same_extention && ~strcmp(ext1, ext2)
        msg = sprintf('File %s (%d, %d) mismatch extention file %s (%d, %d)',...
                      f1, iFile, 1,...
                      f2, iFile, iData);
        error(msg);
      end
    end
  end

end

function [basename, suffix] = split_suffix(fname)
  basename = fname;
  suffix = '';

  pos = strfind(fname, '_');
  if isempty(pos)
    return
  end

  basename = fname(1:pos(end) - 1);
  suffix = fname(pos(end): end);
end

function [basename, ext] = split_extention(fname)
  basename = fname;
  ext = '';

  pos = strfind(fname, '.');
  if isempty(pos)
    return
  end

  basename = fname(1:pos(1) - 1);
  ext = fname(pos(1): end);
end
