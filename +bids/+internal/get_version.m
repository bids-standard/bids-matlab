function version_number = get_version()
  %
  % Reads the version number of the pipeline from the txt file in the root of the
  % repository.
  %
  % USAGE::
  %
  %   version_number = bids.internal.get_version()
  %
  % :returns: :version_number: (char) Use semantic versioning format (like v0.1.0)
  %

  % (C) Copyright 2022 BIDS-MATLAB developers

  try
    version_number = fileread(fullfile(fileparts(mfilename('fullpath')), ...
                                       '..', '..', 'version.txt'));
  catch

    version_number = 'v0.1.0dev ';

  end

  % dirty hack to get rid of line return
  version_number = version_number(1:end - 1);
end
