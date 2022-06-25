function success = run_tests(with_coverage)
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  fprintf('\nRunning tests\n');

  if nargin < 1
    with_coverage = true;
  end

  addpath(fullfile(pwd, 'tests', 'utils'));

  folderToCover = fullfile(pwd, '+bids');
  testFolder = fullfile(pwd, 'tests');

  if with_coverage
    success = moxunit_runtests(testFolder, ...
                               '-verbose', ...
                               '-recursive', ...
                               '-with_coverage', ...
                               '-cover', folderToCover, ...
                               '-cover_xml_file', 'coverage.xml');

  else
    success = moxunit_runtests(testFolder, ...
                               '-verbose', ...
                               '-recursive');

  end

end
