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
  %   write_test_definition_to_file(input, output, trans, test_name, 'compute');
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

function test_Add_to_specific_rows
  %% GIVEN
  transformers(1).Name = 'Add';
  transformers(1).Input = 'onset';
  transformers(1).Query = 'familiarity == Famous face';
  transformers(1).Value = 3;

  % WHEN
  data = face_rep_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.onset, [5; 4; 8; 8]);

end

function test_Subtract_to_specific_rows

  %% GIVEN
  transformers(1).Name = 'Subtract';
  transformers(1).Input = 'onset';
  transformers(1).Query = 'response_time < 2';
  transformers(1).Value = 1;

  % WHEN
  data = face_rep_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.onset, [1; 4; 4; 8]);

end

function test_Add_coerce_value

  %% GIVEN
  transformers(1).Name = 'Add';
  transformers(1).Input = 'onset';
  transformers(1).Value = '3';

  % WHEN
  data = vis_motion_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.onset, [5; 7]);

  %% GIVEN
  transformers(1).Name = 'Add';
  transformers(1).Input = 'onset';
  transformers(1).Value = '+';

  % WHEN
  assertExceptionThrown(@()bids.transformers(transformers, vis_motion_events()), ...
                        'Basic:numericOrCoercableToNumericRequired');

  % THEN
  assertEqual(new_content.onset, [5; 7]);

end

function test_Constant_basic()

  %% GIVEN
  transformers = struct('Name', 'Constant', ...
                        'Output', 'cst');

  % WHEN
  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  assertEqual(new_content.cst, ones(4, 1));

end

function test_Constant_with_value()

  %% GIVEN
  transformers = struct('Name', 'Constant', ...
                        'Value', 2, ...
                        'Output', 'cst');

  % WHEN
  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  assertEqual(new_content.cst, ones(4, 1) * 2);

end

function test_Divide_several_inputs

  % GIVEN
  transformers(1).Name = 'Divide';
  transformers(1).Input = {'onset', 'duration'};
  transformers(1).Value = 2;

  % WHEN
  data = vis_motion_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.onset, [1; 2]);
  assertEqual(new_content.duration, [1; 1]);

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

  if bids.internal.is_octave
    return
  end

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

function test_Product()

  % GIVEN
  transformers = struct('Name', 'Product', ...
                        'Input', {{'onset', 'duration'}}, ...
                        'Output', 'onset_times_duration');

  % WHEN
  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.onset_times_duration, [4; 8; 12; 16]);

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

  if bids.internal.is_octave
    return
  end

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

function test_Sum()

  % GIVEN
  transformers = struct('Name', 'Sum', ...
                        'Input', {{'onset', 'duration'}}, ...
                        'Output', 'onset_plus_duration');

  % WHEN
  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.onset_plus_duration, [4; 6; 8; 10]);

end

function test_Sum_with_weights()

  % GIVEN
  transformers = struct('Name', 'Sum', ...
                        'Input', {{'onset', 'duration'}}, ...
                        'Weights', [2, 1], ...
                        'Output', 'onset_plus_duration_with_weight');

  % WHEN
  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.onset_plus_duration_with_weight, [6; 10; 14; 18]);

end

function test_Power

  %% GIVEN
  transformers.Name = 'Power';
  transformers.Input = 'intensity';
  transformers.Value = 2;

  % WHEN
  data = vis_motion_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.intensity, [4; 16]);
end

function test_Power_with_output

  %% GIVEN
  transformers.Name = 'Power';
  transformers.Input = 'intensity';
  transformers.Value = 3;
  transformers.Output = 'intensity_cubed';

  % WHEN
  data = vis_motion_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.intensity_cubed, [8; -64]);

end

function test_Scale()

  % omit nan not implemented in octave
  if bids.internal.is_octave
    return
  end

  %% GIVEN
  transformers = struct('Name', 'Scale', ...
                        'Input', {{'age'}});

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertElementsAlmostEqual(new_content.age, ...
                            [-0.1769; -0.3699; 1.4315; -0.8846; nan], ...
                            'absolute', 1e-3);

end

function test_Scale_all_options()

  % omit nan not implemented in octave
  if bids.internal.is_octave
    return
  end

  %% GIVEN
  transformers = struct('Name', 'Scale', ...
                        'Input', {{'age'}}, ...
                        'Demean', true, ...
                        'Rescale', true, ...
                        'ReplaceNa', 'off', ...
                        'Output', {{'age_demeaned_centered'}});

  % WHEN
  data = participants();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertElementsAlmostEqual(new_content.age_demeaned_centered, ...
                            [-0.1769; -0.3699; 1.4315; -0.8846; nan], ...
                            'absolute', 1e-3);
end

function test_multi_Scale_nan_after()

  % omit nan not implemented in octave
  if bids.internal.is_octave
    return
  end

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

  % omit nan not implemented in octave
  if bids.internal.is_octave
    return
  end

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

function test_Subtract

  % GIVEN
  transformers(1).Name = 'Subtract';
  transformers(1).Input = 'onset';
  transformers(1).Value = 3;

  % WHEN
  data = vis_motion_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.onset, [-1; 1]);

end

function test_Threshold_with_output()

  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Output', 'tmp');

  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  assertEqual(new_content.tmp, [1; 2; 0; 0]);

end

function test_Threshold()

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold');

  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.to_threshold, [1; 2; 0; 0]);

end

function test_Threshold_with_threshold_specified()

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Threshold', 1);

  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.to_threshold, [0; 2; 0; 0]);

end

function test_Threshold_binarize()

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Binarize', true);

  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.to_threshold, [1; 1; 0; 0]);

end

function test_Threshold_binarize_above()

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Binarize', true, ...
                        'Above', false);

  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.to_threshold, [0; 0; 1; 1]);

end

function test_Threshold_binarize_above_singed()

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Threshold', 1, ...
                        'Binarize', true, ...
                        'Above', true, ...
                        'Signed', false);

  data = vis_motion_to_threshold_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  % THEN
  assertEqual(new_content.to_threshold, [0; 1; 0; 1]);

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
