function success = run_tests(with_coverage)
  %

  % (C) Copyright 2021 BIDS-MATLAB developers

  fprintf('\nRunning tests\n');

  if nargin < 1
    with_coverage = true;
  end

  if ispc
    with_coverage = false;
  end

  addpath(fullfile(pwd, 'tests', 'utils'));

  folderToCover = fullfile(pwd, '+bids');

  testFolder = fullfile(pwd, 'tests');
  if run_slow_test_only
    testFolder = fullfile(pwd, 'tests', 'tests_slow');
  end

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
                               '-randomize_order', ...
                               '-recursive');

  end

end
