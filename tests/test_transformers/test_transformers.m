function test_suite = test_transformers %#ok<*STOUT>
  %

  % (C) Copyright 2022 Remi Gau

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end

  initTestSuite;

end

function data_dir = variable_spec_dir()

  data_dir = fullfile(fileparts(mfilename('fullpath')), '..');

  PLATFORM  = getenv('PLATFORM');

  if strcmp(PLATFORM, 'GITHUB_ACTIONS')

    data_dir = fullfile('/', 'github', 'workspace', 'tests');

  end

  data_dir =  fullfile(data_dir, 'variable-transform', 'spec');

  if exist(data_dir, 'dir') ~= 7
    msg = sprintf([ ...
                   'The variable-transform folder %s was not found.\n', ...
                   'Install it in the tests folder with:\n', ...
                   'git clone git://github.com/bids-standard/variable-transform.git --depth 1']);
    error(msg); %#ok<SPERR>
  end

  data_dir =  bids.internal.file_utils(data_dir, 'cpath');

end

function run_all_transformers_from_spec(category, skip_list)

  all_tests = bids.internal.file_utils('FPList', ...
                                       fullfile(variable_spec_dir(), category), ...
                                       'dir', ...
                                       '.*');

  errors = {};
  failures = {};

  fprintf(1, '\n');

  for i = 1:size(all_tests, 1)

    test_folder = deblank(all_tests(i, :));

    transform_name = bids.internal.file_utils(test_folder, 'basename');

    if ismember(transform_name, skip_list)
      continue
    end

    status = run_single_transformer(variable_spec_dir(), category, transform_name, false);

    if status == 125
      errors{1, end + 1} = transform_name; %#ok<*AGROW>
    elseif status == 1
      failures{1, end + 1} = transform_name;
    end

  end

  if numel(errors) > 1
    warning('\nThe following tests failed to run: \n\t- %s \n', strjoin(errors, '\n\t- '));
  end

  if numel(failures) > 1
    error('\nThe following tests failed: \n\t- %s \n', strjoin(failures, '\n\t- '));
  end

end

function [status, ME] = run_single_transformer(test_folder, category, transform_name, verbose)

  ME = '';

  fprintf('\trunning test for %s "%s": ', category, transform_name);

  subfolder = fullfile(test_folder, category, transform_name);

  input = bids.util.tsvread(fullfile(subfolder, 'input.tsv'));

  try
    expected = bids.util.tsvread(fullfile(subfolder, 'output.tsv'));
    transform = bids.util.jsondecode(fullfile(subfolder, 'transformation.json'));
  catch
    fprintf('ERROR \n');
    status = 125;
    return
  end

  try
    new_content = bids.transformers(transform.Instruction, input);
    bids.util.tsvwrite('tmp.tsv', new_content);
    new_content = bids.util.tsvread('tmp.tsv');
    assertEqual(new_content, expected);
  catch ME
    fprintf('FAILED \n');
    status = 1;

    if  verbose
      fprintf(1, 'Expected: \n');
      disp(expected);
      fprintf(1, 'Actual: \n');
      disp(new_content);
      fprintf(1, '\n');
    end

    return
  end

  fprintf('PASSED \n');
  status = 0;

end

function test_compute()
  skip_list = {};
  run_all_transformers_from_spec('compute', skip_list);
end

function test_munge()
  skip_list = {};
  run_all_transformers_from_spec('munge', skip_list);
end

% function test_single_transformer()
%   [status, ME] = run_single_transformer(fullfile(variable_spec_dir()), ...
%                                         'compute', 'Scale', ...
%                                         true);
%   if status == 1
%     rethrow(ME);
%   end
% end
