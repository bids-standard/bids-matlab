function test_suite = test_transformers_compute %#ok<*STOUT>
  %

  % (C) Copyright 2022 Remi Gau

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end

  initTestSuite;

end

%% COMPUTE

function write_definition(input, output, trans, stack)
  test_name = stack.name;
  % write_test_definition_to_file(input, output, trans, test_name, 'compute');
end

%% multi step

function test_multi_add_subtract_with_output

  % GIVEN
  transformers(1).Name = 'Subtract';
  transformers(1).Input = 'onset';
  transformers(1).Value = 3;
  transformers(1).Output = 'onset_minus_3';

  transformers(2).Name = 'Add';
  transformers(2).Input = 'onset';
  transformers(2).Value  = 1;
  transformers(2).Output  = 'onset_plus_1';

  % WHEN
  data = vis_motion_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assert(all(ismember({'onset_plus_1'; 'onset_minus_3'}, fieldnames(new_content))));
  assertEqual(new_content.onset_plus_1, [3; 5]);
  assertEqual(new_content.onset_minus_3, [-1; 1]);

end

%% single step

function test_Add_unchanged_data_when_variable_to_query_is_missing

  %% GIVEN
  transformers(1).Name = 'Subtract';
  transformers(1).Input = 'onset';
  transformers(1).Query = 'foo < 2';
  transformers(1).Value = 1;

  % WHEN
  data = face_rep_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(data, new_content);

end

function test_Mean()

  % GIVEN
  transformers = struct('Name', 'Mean', ...
                        'Input', {{'age'}});

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.age_mean, nan);

end

function test_Mean_with_output()

  % GIVEN
  transformers = struct('Name', 'Mean', ...
                        'Input', {{'age'}}, ...
                        'Output', 'age_mean_omitnan', ...
                        'OmitNan', true);

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.age_mean_omitnan, 23.75);

end

function test_StdDev()

  % GIVEN
  transformers = struct('Name', 'StdDev', ...
                        'Input', {{'age'}});

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.age_std, nan);

end

function test_StdDev_omitnan()

  % GIVEN
  transformers = struct('Name', 'StdDev', ...
                        'Input', {{'age'}}, ...
                        'Output', 'age_std_omitnan', ...
                        'OmitNan', true);

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertElementsAlmostEqual(new_content.age_std_omitnan, 15.543, 'absolute', 1e-3);

end

function test_multi_Scale_nan_after()

  %% GIVEN
  transformers{1} = struct('Name', 'Scale', ...
                           'Input', {{'age'}}, ...
                           'Rescale', false, ...
                           'Output', {{'age_not_rescaled'}});
  transformers{2} = struct('Name', 'Scale', ...
                           'Input', {{'age'}}, ...
                           'Demean', false, ...
                           'Output', {{'age_not_demeaned'}});
  transformers{3} = struct('Name', 'Scale', ...
                           'Input', {{'age'}}, ...
                           'ReplaceNa', 'after', ...
                           'Rescale', false, ...
                           'Output', {{'age_not_rescaled_after'}});
  transformers{4} = struct('Name', 'Scale', ...
                           'Input', {{'age'}}, ...
                           'ReplaceNa', 'after', ...
                           'Demean', false, ...
                           'Output', {{'age_not_demeaned_after'}});
  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertElementsAlmostEqual(new_content.age_not_rescaled, ...
                            [-2.7500; -5.7500; 22.2500; -13.7500; nan], ...
                            'absolute', 1e-3);
  assertElementsAlmostEqual(new_content.age_not_demeaned, ...
                            [1.3511; 1.1581; 2.9595; 0.6434; nan], ...
                            'absolute', 1e-3);
  assertElementsAlmostEqual(new_content.age_not_rescaled_after, ...
                            [-2.7500; -5.7500; 22.2500; -13.7500; 0], ...
                            'absolute', 1e-3);
  assertElementsAlmostEqual(new_content.age_not_demeaned_after, ...
                            [1.3511; 1.1581; 2.9595; 0.6434; 0], ...
                            'absolute', 1e-3);
end

function test_multi_scale_nan_before()

  %% GIVEN
  transformers{1} = struct('Name', 'Scale', ...
                           'Input', {{'age'}}, ...
                           'ReplaceNa', 'before', ...
                           'Output', {{'age_before'}});
  transformers{2} = struct('Name', 'Scale', ...
                           'Input', {{'age'}}, ...
                           'ReplaceNa', 'before', ...
                           'Rescale', false, ...
                           'Output', {{'age_not_rescaled_before'}});
  transformers{3} = struct('Name', 'Scale', ...
                           'Input', {{'age'}}, ...
                           'ReplaceNa', 'before', ...
                           'Demean', false, ...
                           'Output', {{'age_not_demeaned_before'}});

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertElementsAlmostEqual(new_content.age_before, ...
                            [0.1166; -0.0583; 1.5747; -0.5249; -1.1081], ...
                            'absolute', 1e-3);
  assertElementsAlmostEqual(new_content.age_not_rescaled_before, ...
                            [2; -1; 27; -9; -19], ...
                            'absolute', 1e-3);
  assertElementsAlmostEqual(new_content.age_not_demeaned_before, ...
                            [1.2247; 1.0498; 2.6828; 0.5832; 0], ...
                            'absolute', 1e-3);
end

%% Helper functions

function cfg = set_up()
  cfg = set_test_cfg();
  cfg.this_path = fileparts(mfilename('fullpath'));
end

function value = dummy_data_dir()
  cfg = set_up();
  value = fullfile(cfg.this_path, 'data', 'tsv_files');
end
