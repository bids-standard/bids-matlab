function test_suite = test_bids_examples %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_examples_basic()
  % Test datasets from https://github.com/bids-standard/bids-examples
  %
  % This repository is downloaded automatically by the continuous integration
  % framework and is required for the tests to be run.
  %
  % List all the directories in the bids-example folder that are actual
  % datasets
  pth_bids_example = get_test_data_dir();

  d = dir(pth_bids_example);
  d(arrayfun(@(x) ~x.isdir || ismember(x.name, {'.', '..', '.git', '.github'}), d)) = [];

  % -Try to run bids.layout on each dataset directory and keep track of any
  % failure with a try/catch
  status = false(1, numel(d));
  msg = cell(1, numel(d));
  for i = 1:numel(d)
    if exist(fullfile(pth_bids_example, d(i).name, '.SKIP_VALIDATION'), 'file')
      status(i) = true;
      fprintf('-');
      continue
    end
    try
      BIDS = bids.layout(fullfile(pth_bids_example, d(i).name), ...
                         'use_schema', true, ...
                         'index_derivatives', false, ...
                         'tolerant', false, ...
                         'verbose', false);
      status(i) = true;
      fprintf('.');
    catch err
      fprintf('X');
      msg{i} = err.message;
    end
  end
  fprintf('\n');

  % lists all the folder for which bids.layout failed
  if ~all(status)
    for i = find(~status)
      fprintf('* %s: %s\n', d(i).name, msg{i});
    end
    error('Parsing of BIDS-compatible datasets failed.');
  end

end
