function success = run_tests()
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  with_coverage = false;

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
