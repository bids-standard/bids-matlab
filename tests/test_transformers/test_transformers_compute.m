function test_suite = test_transformers_compute %#ok<*STOUT>
  %
  % (C) Copyright 2022 Remi Gau

  if bids.internal.is_octave
    return
  end

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end

  initTestSuite;

end

%% COMPUTE

%% multi step

function test_add_subtract_with_output

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
  new_content = bids.transformers(transformers, vis_motion_events());

  % THEN
  assert(all(ismember({'onset_plus_1'; 'onset_minus_3'}, fieldnames(new_content))));
  assertEqual(new_content.onset_plus_1, [3; 5]);
  assertEqual(new_content.onset_minus_3, [-1; 1]);

end

%% single step

function test_basic_to_specific_rows
  %% GIVEN
  transformers(1).Name = 'Add';
  transformers(1).Input = 'onset';
  transformers(1).Query = 'familiarity == Famous face';
  transformers(1).Value = 3;

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  % THEN
  assertEqual(new_content.onset, [5; 4; 8; 8]);

  %% GIVEN
  transformers(1).Name = 'Subtract';
  transformers(1).Input = 'onset';
  transformers(1).Query = 'response_time < 2';
  transformers(1).Value = 1;

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  % THEN
  assertEqual(new_content.onset, [1; 4; 4; 8]);

end

function test_add_coerce_value

  %% GIVEN
  transformers(1).Name = 'Add';
  transformers(1).Input = 'onset';
  transformers(1).Value = '3';

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.onset, [5; 7]);

  %% GIVEN
  transformers(1).Name = 'Add';
  transformers(1).Input = 'onset';
  transformers(1).Value = '+';

  % WHEN
  assertExceptionThrown(@()bids.transformers(transformers, vis_motion_events()), ...
                        'basic:numericOrCoercableToNumericRequired');

  % THEN
  assertEqual(new_content.onset, [5; 7]);

end

function test_constant()

  %% GIVEN
  transformers = struct('Name', 'Constant', ...
                        'Output', 'cst');

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  assertEqual(new_content.cst, ones(4, 1));

  %% GIVEN
  transformers = struct('Name', 'Constant', ...
                        'Value', 2, ...
                        'Output', 'cst');

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  assertEqual(new_content.cst, ones(4, 1) * 2);

end

function test_divide_several_inputs

  % GIVEN
  transformers(1).Name = 'Divide';
  transformers(1).Input = {'onset', 'duration'};
  transformers(1).Value = 2;

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.onset, [1; 2]);
  assertEqual(new_content.duration, [1; 1]);

end

function test_mean()

  % GIVEN
  transformers = struct('Name', 'Mean', ...
                        'Input', {{'age'}});

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content.age_mean, nan);

  % GIVEN
  transformers = struct('Name', 'Mean', ...
                        'Input', {{'age'}}, ...
                        'Output', 'age_mean_omitnan', ...
                        'OmitNan', true);

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content.age_mean_omitnan, 23.75);

end

function test_product()

  % GIVEN
  transformers = struct('Name', 'Product', ...
                        'Input', {{'onset', 'duration'}}, ...
                        'Output', 'onset_times_duration');

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.onset_times_duration, [4; 8; 12; 16]);

end

function test_std()

  % GIVEN
  transformers = struct('Name', 'StdDev', ...
                        'Input', {{'age'}});

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content.age_std, nan);

  % GIVEN
  transformers = struct('Name', 'StdDev', ...
                        'Input', {{'age'}}, ...
                        'Output', 'age_std_omitnan', ...
                        'OmitNan', true);

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertElementsAlmostEqual(new_content.age_std_omitnan, 15.543, 'absolute', 1e-3);

end

function test_sum()

  % GIVEN
  transformers = struct('Name', 'Sum', ...
                        'Input', {{'onset', 'duration'}}, ...
                        'Output', 'onset_plus_duration');

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.onset_plus_duration, [4; 6; 8; 10]);

  % GIVEN
  transformers = struct('Name', 'Sum', ...
                        'Input', {{'onset', 'duration'}}, ...
                        'Weights', [2, 1], ...
                        'Output', 'onset_plus_duration_with_weight');

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.onset_plus_duration_with_weight, [6; 10; 14; 18]);

end

function test_power

  %% GIVEN
  transformers.Name = 'Power';
  transformers.Input = 'intensity';
  transformers.Value = 2;

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.intensity, [4; 16]);

  %% GIVEN
  transformers.Name = 'Power';
  transformers.Input = 'intensity';
  transformers.Value = 3;
  transformers.Output = 'intensity_cubed';

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.intensity_cubed, [8; -64]);

end

function test_scale()

  %% GIVEN
  transformers = struct('Name', 'Scale', ...
                        'Input', {{'age'}});

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertElementsAlmostEqual(new_content.age, ...
                            [-0.1769; -0.3699; 1.4315; -0.8846; nan], ...
                            'absolute', 1e-3);

  %% GIVEN
  transformers = struct('Name', 'Scale', ...
                        'Input', {{'age'}}, ...
                        'Demean', true, ...
                        'Rescale', true, ...
                        'ReplaceNa', 'off', ...
                        'Output', {{'age_demeaned_centered'}});

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertElementsAlmostEqual(new_content.age_demeaned_centered, ...
                            [-0.1769; -0.3699; 1.4315; -0.8846; nan], ...
                            'absolute', 1e-3);
end

function test_scale_nan_after()

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
  new_content = bids.transformers(transformers, participants());

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

function test_scale_nan_before()

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
  new_content = bids.transformers(transformers, participants());

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

function test_subtract

  % GIVEN
  transformers(1).Name = 'Subtract';
  transformers(1).Input = 'onset';
  transformers(1).Value = 3;

  % WHEN
  new_content = bids.transformers(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.onset, [-1; 1]);

end

function test_threshold_output()

  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Output', 'tmp');

  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  assertEqual(new_content.tmp, [1; 2; 0; 0]);

end

function test_threshold()

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold');

  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.to_threshold, [1; 2; 0; 0]);

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Threshold', 1);

  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.to_threshold, [0; 2; 0; 0]);

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Binarize', true);

  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.to_threshold, [1; 1; 0; 0]);

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Binarize', true, ...
                        'Above', false);

  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.to_threshold, [0; 0; 1; 1]);

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Threshold', 1, ...
                        'Binarize', true, ...
                        'Above', true, ...
                        'Signed', false);

  new_content = bids.transformers(transformers, vis_motion_to_threshold_events());

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
