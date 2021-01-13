function test_suite = test_bids_examples %#ok<*STOUT>
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions(); %#ok<*NASGU>
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;
end

function test_bids_examples_basic()
  % Test datasets from https://github.com/bids-standard/bids-examples
  % This repository is downloaded automatically by the continuous integration
  % framework and is required for the tests to be run.
  % __________________________________________________________________________
  %
  % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
  %   The brain imaging data structure, a format for organizing and
  %   describing outputs of neuroimaging experiments.
  %   K. J. Gorgolewski et al, Scientific Data, 2016.
  % __________________________________________________________________________

  % Copyright (C) 2019, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2019--, BIDS-MATLAB developers

  % -List all the directories in the bids-example folder that are actual
  % datasets
  pth = fullfile(pwd, 'bids-examples');

  d = dir(pth);
  d(arrayfun(@(x) ~x.isdir || ismember(x.name, {'.', '..', '.git', '.github'}), d)) = [];

  % -Try to run bids.layout on each dataset directory and keep track of any
  % failure with a try/catch
  sts = false(1, numel(d));
  msg = cell(1, numel(d));
  for i = 1:numel(d)
    if exist(fullfile(pth, d(i).name, '.SKIP_VALIDATION'), 'file')
      sts(i) = true;
      fprintf('-');
      continue
    end
    try
      BIDS = bids.layout(fullfile(pth, d(i).name));
      sts(i) = true;
      fprintf('.');
    catch err
      fprintf('X');
      msg{i} = err.message;
    end
  end
  fprintf('\n');

  % lists all the folder for which bids.layout failed
  if ~all(sts)
    for i = find(~sts)
      fprintf('* %s: %s\n', d(i).name, msg{i});
    end
    error('Parsing of BIDS-compatible datasets failed.');
  end

end