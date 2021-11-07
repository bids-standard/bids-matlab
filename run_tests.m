function success = run_tests()
  %
  % (C) Copyright 2021 BIDS-MATLAB developers

  addpath(fullfile(pwd, 'tests', 'utils'));

  folderToCover = fullfile(pwd, '+bids');
  testFolder = fullfile(pwd, 'tests');

  success = moxunit_runtests(testFolder, ...
                             '-verbose', ...
                             '-recursive', ...
                             '-with_coverage', ...
                             '-cover', folderToCover, ...
                             '-cover_xml_file', 'coverage.xml');

end
