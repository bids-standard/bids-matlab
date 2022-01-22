function version_number = bids_matlab_version()
  %
  % Reads the version number of the pipeline from the txt file in the root of the
  % repository.
  %
  % USAGE::
  %
  %   version_number = bids_matlab_version()
  %
  % :returns: :version_number: (string) Use semantic versioning format (like v0.1.0)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  try
    version_number = fileread(fullfile(fileparts(mfilename('fullpath')), '..', 'version.txt'));
  catch

    version_number = 'v0.1.0 ';

  end

  % dirty hack to get rid of line return
  version_number = version_number(1:end - 1);
end
