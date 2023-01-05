function test_suite = test_transformers_compute_logical %#ok<*STOUT>
  %

  % (C) Copyright 2022 Remi Gau

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end

  initTestSuite;

end

function write_definition(input, output, trans, stack, suffix)

  test_name = stack.name;
  if nargin == 5
    test_name = [test_name '_' suffix];
  end
  %     write_test_definition_to_file(input, output, trans, test_name, 'compute');

end

%% LOGICAL

function test_And()

  % GIVEN
  transformers = struct('Name', 'And', ...
                        'Input', {{'sex_m', 'age_gt_twenty'}}, ...
                        'Output', 'men_gt_twenty');

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.men_gt_twenty, [true; false; false; false; false]);

end

function test_And_nan()

  % GIVEN
  transformers = struct('Name', 'And', ...
                        'Input', {{'handedness', 'age'}}, ...
                        'Output', 'age_or_hand');

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.age_or_hand, [true; true; false; true; false]);

end

function test_Or()

  % GIVEN
  transformers = struct('Name', 'Or', ...
                        'Input', {{'sex_m', 'age_gt_twenty'}}, ...
                        'Output', 'men_or_gt_twenty');

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.men_or_gt_twenty, [true; true; true; false; false]);

end

function test_Not()

  % GIVEN
  transformers = struct('Name', 'Not', ...
                        'Input', {{'age_gt_twenty'}}, ...
                        'Output', 'ager_lt_twenty');

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.ager_lt_twenty, [false; true; false; true; true]);

end
