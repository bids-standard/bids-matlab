function test_suite = test_transformers %#ok<*STOUT>
  %
  % (C) Copyright 2022 Remi Gau

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end

  initTestSuite;

end

function test_assign()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face');

  data = face_rep_events();
  data.Face = [1; 1; 1; 1];

  new_content = bids.transformers.assign(transformers, data);

  assertEqual(new_content.Face, new_content.response_time);

end

function test_assign_with_output()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face', ...
                        'Output', 'new_face');

  data = face_rep_events();
  data.Face = [1; 1; 1; 1];

  new_content = bids.transformers.assign(transformers, data);

  assertEqual(new_content.new_face, new_content.response_time);

end

function test_assign_with_output_and_input_attribute()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face', ...
                        'Output', 'new_face', ...
                        'InputAttr', 'onset');

  data = face_rep_events();
  data.Face = [1; 1; 1; 1];

  new_content = bids.transformers.assign(transformers, data);

  assertEqual(new_content.new_face, new_content.onset);

end

function test_assign_with_target_attribute()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face', ...
                        'TargetAttr', 'duration');

  data = face_rep_events();
  data.Face = [1; 1; 1; 1];

  new_content = bids.transformers.assign(transformers, data);

  expected.response_time = [data.response_time; nan(size(data.response_time))];
  expected.Face = [nan(size(data.response_time)); data.response_time];
  expected.duration = [nan(size(data.duration)); data.duration];

  assertEqual(new_content.response_time, expected.response_time);
  assertEqual(new_content.Face, expected.Face);

end

function test_assign_missing_target()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face');

  assertExceptionThrown(@()bids.transformers.assign(transformers, face_rep_events()), ...
                        'check_field:missingTarget');

end

function test_no_transformation()

  transformers = struct([]);

  new_content = bids.transformers(participants(), transformers);

  assertEqual(new_content, participants());

end

%% SIDE FUNCTIONS

function test_get_input()

  %% GIVEN
  transformers = struct('Input', {{'onset'}});
  data = vis_motion_to_threshold_events();

  % WHEN
  inputs = bids.transformers.get_input(transformers, data);

  assertEqual(inputs, {'onset'});

  %% GIVEN
  transformers = struct('Input', {{'onset', 'foo', 'bar'}});
  data = vis_motion_to_threshold_events();

  % WHEN
  assertExceptionThrown(@()bids.transformers.get_input(transformers, data), ...
                        'check_field:missingInput');

end

%% LOGICAL

function test_and()

  % GIVEN
  transformers = struct('Name', 'And', ...
                        'Input', {{'sex_m', 'age_gt_twenty'}}, ...
                        'Output', 'men_gt_twenty');

  % WHEN
  new_content = bids.transformers.logical(transformers, participants());

  % THEN
  assertEqual(new_content.men_gt_twenty, [true; false; false; false; false]);

end

function test_or()

  % GIVEN
  transformers = struct('Name', 'Or', ...
                        'Input', {{'sex_m', 'age_gt_twenty'}}, ...
                        'Output', 'men_or_gt_twenty');

  % WHEN
  new_content = bids.transformers.logical(transformers, participants());

  % THEN
  assertEqual(new_content.men_or_gt_twenty, [true; true; true; false; false]);

end

function test_not()

  % GIVEN
  transformers = struct('Name', 'Not', ...
                        'Input', {{'age_gt_twenty'}}, ...
                        'Output', 'ager_lt_twenty');

  % WHEN
  new_content = bids.transformers.logical(transformers, participants());

  % THEN
  assertEqual(new_content.ager_lt_twenty, [false; true; false; true; true]);

end

%% MUNGE

%% multi step

function test_touch()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-TouchBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers{1} = struct('Name', 'Threshold', ...
                           'Input', 'duration', ...
                           'Binarize', true, ...
                           'Output', 'tmp');
  transformers{2} = struct('Name', 'Replace', ...
                           'Input', 'tmp', ...
                           'Output', 'duration', ...
                           'Attribute', 'duration', ...
                           'Replace', struct('duration_1', 1));
  transformers{3} = struct('Name', 'Delete', ...
                           'Input', {{'tmp'}});

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(fieldnames(tsv_content), fieldnames(new_content));

end

function test_combine_columns()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers{1} = struct('Name', 'Filter', ...
                           'Input', 'face_type', ...
                           'Query', 'face_type==famous', ...
                           'Output', 'Famous');
  transformers{2} = struct('Name', 'Filter', ...
                           'Input', 'repetition_type', ...
                           'Query', 'repetition_type==1', ...
                           'Output', 'FirstRep');
  transformers{3} = struct('Name', 'And', ...
                           'Input', {{'Famous', 'FirstRep'}}, ...
                           'Output', 'tmp');
  transformers{4} = struct('Name', 'Replace', ...
                           'Input', 'tmp', ...
                           'Output', 'trial_type', ...
                           'Replace', struct('tmp_1', 'FamousFirstRep'));
  transformers{5} = struct('Name', 'Delete', ...
                           'Input', {{'tmp', 'Famous', 'FirstRep'}});

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(fieldnames(tsv_content), fieldnames(new_content));
  assertEqual(unique(new_content.trial_type), {'FamousFirstRep'; 'face'});

end

function test_complex_filter_with_and()

  %% GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers{1} = struct('Name', 'Filter', ...
                           'Input', 'face_type', ...
                           'Query', 'face_type==famous', ...
                           'Output', 'Famous');
  transformers{2} = struct('Name', 'Filter', ...
                           'Input', 'repetition_type', ...
                           'Query', 'repetition_type==1', ...
                           'Output', 'FirstRep');

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assert(all(ismember({'Famous'; 'FirstRep'}, fieldnames(new_content))));
  assertEqual(sum(strcmp(new_content.Famous, 'famous')), 52);
  assertEqual(unique(new_content.Famous), {''; 'famous'});
  assertEqual(nansum(new_content.FirstRep), 52);

  %% GIVEN
  transformers{3} = struct('Name', 'And', ...
                           'Input', {{'Famous', 'FirstRep'}}, ...
                           'Output', 'FamousFirstRep');

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(sum(new_content.FamousFirstRep), 26);

end

%% single step

function test_filter()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionAfter_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Filter', ...
                        'Input', 'trial_type', ...
                        'Query', 'trial_type==F1', ...
                        'Output', 'Famous_1');

  % WHEN
  new_content = bids.transformers.filter(transformers, tsv_content);

  % THEN
  assert(all(ismember({'Famous_1'}, fieldnames(new_content))));
  assertEqual(numel(new_content.Famous_1), 104);
  assertEqual(unique(new_content.Famous_1), {''; 'F1'});

end

function test_concatenate()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), ...
                     'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Concatenate', ...
                        'Input', {{'face_type', 'repetition_type'}}, ...
                        'Output', 'trial_type');

  % WHEN
  new_content = bids.transformers.concatenate(transformers, tsv_content);

  assertEqual(unique(new_content.trial_type), ...
              {'famous_1'; 'famous_2';  'unfamiliar_1'; 'unfamiliar_2'});

end

function test_replace()

  %% GIVEN
  tsvFile = fullfile(dummy_data_dir(), ...
                     'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers(1).Name = 'Replace';
  transformers(1).Input = 'face_type';
  transformers(1).Replace = struct('famous', 'foo');

  % WHEN
  new_content = bids.transformers.replace(transformers, tsv_content);

  % THEN
  assertEqual(unique(new_content.face_type), {'foo'; 'unfamiliar'});

  %% GIVEN
  transformers(1).Name = 'Replace';
  transformers(1).Input = 'face_type';
  transformers(1).Replace = struct('duration_0', 1);
  transformers(1).Attribute = 'duration';

  % WHEN
  new_content = bids.transformers.replace(transformers, tsv_content);

  % THEN
  assertEqual(unique(new_content.duration), 1);

end

function test_replace_with_output()

  %% GIVEN
  tsvFile = fullfile(dummy_data_dir(), ...
                     'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers(1).Name = 'Replace';
  transformers(1).Input = 'face_type';
  transformers(1).Output = 'tmp';
  transformers(1).Replace = struct('duration_0', 1);
  transformers(1).Attribute = 'duration';

  % WHEN
  new_content = bids.transformers.replace(transformers, tsv_content);

  % THEN
  assertEqual(unique(new_content.tmp), 1);

end

function test_copy()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Copy', ...
                        'Input', {{'face_type', 'repetition_type'}}, ...
                        'Output', {{'foo', 'bar'}});
  new_content = bids.transformers.copy(transformers, tsv_content);

  assert(all(ismember({'foo'; 'bar'}, fieldnames(new_content))));
  assertEqual(new_content.foo, new_content.face_type);
  assertEqual(new_content.bar, new_content.repetition_type);

end

function test_filter_by()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Filter', ...
                        'Input', 'face_type', ...
                        'Query', 'repetition_type==1', ...
                        'By', 'repetition_type', ...
                        'Output', 'face_type_repetition_1');

  % WHEN
  new_content = bids.transformers.filter(transformers, tsv_content);

  % THEN
  % TODO

end

function test_delete_select()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Delete', ...
                        'Input', 'face_type');

  new_content = bids.transformers.delete(transformers, tsv_content);

  assert(~(ismember({'face_type'}, fieldnames(new_content))));

  % GIVEN
  transformers = struct('Name', 'Select', ...
                        'Input', 'face_type');

  new_content = bids.transformers.select(transformers, tsv_content);

  assertEqual({'face_type'}, fieldnames(new_content));

end

function test_rename()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Rename', ...
                        'Input', {{'face_type', 'repetition_type'}}, ...
                        'Output', {{'foo', 'bar'}});
  new_content = bids.transformers.rename(transformers, tsv_content);

  assert(all(ismember({'foo'; 'bar'}, fieldnames(new_content))));
  assert(all(~ismember({'face_type'; 'repetition_type'}, fieldnames(new_content))));
  assertEqual(new_content.foo, tsv_content.face_type);
  assertEqual(new_content.bar, tsv_content.repetition_type);

end

function test_factor()

  % GIVEN
  transformers = struct('Name', 'Factor', ...
                        'Input', {{'familiarity'}});

  % WHEN
  new_content = bids.transformers.factor(transformers, face_rep_events());

  % THEN
  assert(isfield(new_content, 'familiarity_1'));
  assert(isfield(new_content, 'familiarity_2'));
  assertEqual(new_content.familiarity_1,  [true; false; true; false]);
  assertEqual(new_content.familiarity_2,  [false; true; false; true]);

end

function test_factor_numeric()

  % GIVEN
  transformers = struct('Name', 'Factor', ...
                        'Input', {{'age'}});

  % WHEN
  new_content = bids.transformers.factor(transformers, participants());

  % THEN
  assert(isfield(new_content, 'age_10'));
  assert(isfield(new_content, 'age_NaN'));
  assertEqual(new_content.age_10,  [false; false; false; true; false]);
  assertEqual(new_content.age_NaN,  [false; false; false; false; true]);

end

function test_split_empty_by()

  % GIVEN
  transformers = struct('Name', 'Split', ...
                        'Input', {{'age'}}, ...
                        'By', {{}});

  % WHEN'
  new_content = bids.transformers.split(transformers, participants());

  % THEN
  assertEqual(new_content, participants);

end

function test_split_simple()

  % GIVEN
  transformers = struct('Name', 'Split', ...
                        'Input', {{'age'}}, ...
                        'By', {{'sex'}});

  % WHEN'
  new_content = bids.transformers.split(transformers, participants());

  % THEN
  assertEqual(new_content.age_BY_sex_M,  [21; 18]);
  assertEqual(new_content.age_BY_sex_F,  [46; 10; nan]);

end

function test_split_nested()

  % GIVEN
  transformers = struct('Name', 'Split', ...
                        'Input', {{'age'}}, ...
                        'By', {{'sex', 'handedness'}});

  % WHEN'
  new_content = bids.transformers.split(transformers, participants());

  % THEN
  assert(isfield(new_content, 'age_BY_handedness_left_BY_sex_M'));
  assertEqual(numel(fieldnames(new_content)), 11);
  assertEqual(new_content.age_BY_handedness_left_BY_sex_M,  18);

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
  new_content = bids.transformers(vis_motion_events(), transformers);

  % THEN
  assert(all(ismember({'onset_plus_1'; 'onset_minus_3'}, fieldnames(new_content))));
  assertEqual(new_content.onset_plus_1, [3; 5]);
  assertEqual(new_content.onset_minus_3, [-1; 1]);

end

%% single step

function test_subtract

  % GIVEN
  transformers(1).Name = 'Subtract';
  transformers(1).Input = 'onset';
  transformers(1).Value = 3;

  % WHEN
  new_content = bids.transformers.basic(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.onset, [-1; 1]);

end

function test_add_coerce_value

  %% GIVEN
  transformers(1).Name = 'Add';
  transformers(1).Input = 'onset';
  transformers(1).Value = '3';

  % WHEN
  new_content = bids.transformers.basic(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.onset, [5; 7]);

  %% GIVEN
  transformers(1).Name = 'Add';
  transformers(1).Input = 'onset';
  transformers(1).Value = '+';

  % WHEN
  assertExceptionThrown(@()bids.transformers.basic(transformers, vis_motion_events()), ...
                        'basic:numericOrCoercableToNumericRequired');

  % THEN
  assertEqual(new_content.onset, [5; 7]);

end

function test_power

  %% GIVEN
  transformers.Name = 'Power';
  transformers.Input = 'intensity';
  transformers.Value = 2;

  % WHEN
  new_content = bids.transformers.basic(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.intensity, [4; 16]);

  %% GIVEN
  transformers.Name = 'Power';
  transformers.Input = 'intensity';
  transformers.Value = 3;
  transformers.Output = 'intensity_cubed';

  % WHEN
  new_content = bids.transformers.basic(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.intensity_cubed, [8; -64]);

end

function test_divide_several_inputs

  % GIVEN
  transformers(1).Name = 'Divide';
  transformers(1).Input = {'onset', 'duration'};
  transformers(1).Value = 2;

  % WHEN
  new_content = bids.transformers.basic(transformers, vis_motion_events());

  % THEN
  assertEqual(new_content.onset, [1; 2]);
  assertEqual(new_content.duration, [1; 1]);

end

function test_constant()

  %% GIVEN
  transformers = struct('Name', 'Constant', ...
                        'Output', 'cst');

  % WHEN
  new_content = bids.transformers.constant(transformers, vis_motion_to_threshold_events());

  assertEqual(new_content.cst, ones(4, 1));

  %% GIVEN
  transformers = struct('Name', 'Constant', ...
                        'Value', 2, ...
                        'Output', 'cst');

  % WHEN
  new_content = bids.transformers.constant(transformers, vis_motion_to_threshold_events());

  assertEqual(new_content.cst, ones(4, 1) * 2);

end

function test_threshold_output()

  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Output', 'tmp');

  new_content = bids.transformers.threshold(transformers, vis_motion_to_threshold_events());

  assertEqual(new_content.tmp, [1; 2; 0; 0]);

end

function test_threshold()

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold');

  new_content = bids.transformers.threshold(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.to_threshold, [1; 2; 0; 0]);

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Threshold', 1);

  new_content = bids.transformers.threshold(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.to_threshold, [0; 2; 0; 0]);

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Binarize', true);

  new_content = bids.transformers.threshold(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.to_threshold, [1; 1; 0; 0]);

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Binarize', true, ...
                        'Above', false);

  new_content = bids.transformers.threshold(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.to_threshold, [0; 0; 1; 1]);

  %% WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Threshold', 1, ...
                        'Binarize', true, ...
                        'Above', true, ...
                        'Signed', false);

  new_content = bids.transformers.threshold(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.to_threshold, [0; 1; 0; 1]);

end

function test_mean()

  % GIVEN
  transformers = struct('Name', 'Mean', ...
                        'Input', {{'age'}});

  % WHEN
  new_content = bids.transformers.mean(transformers, participants());

  % THEN
  assertEqual(new_content.age_mean, nan);

  % GIVEN
  transformers = struct('Name', 'Mean', ...
                        'Input', {{'age'}}, ...
                        'Output', 'age_mean_omitnan', ...
                        'OmitNan', true);

  % WHEN
  new_content = bids.transformers.mean(transformers, participants());

  % THEN
  assertEqual(new_content.age_mean_omitnan, 23.75);

end

function test_std()

  % GIVEN
  transformers = struct('Name', 'StdDev', ...
                        'Input', {{'age'}});

  % WHEN
  new_content = bids.transformers.std(transformers, participants());

  % THEN
  assertEqual(new_content.age_std, nan);

  % GIVEN
  transformers = struct('Name', 'StdDev', ...
                        'Input', {{'age'}}, ...
                        'Output', 'age_std_omitnan', ...
                        'OmitNan', true);

  % WHEN
  new_content = bids.transformers.std(transformers, participants());

  % THEN
  assertElementsAlmostEqual(new_content.age_std_omitnan, 15.543, 'absolute', 1e-3);

end

function test_sum()

  % GIVEN
  transformers = struct('Name', 'Sum', ...
                        'Input', {{'onset', 'duration'}}, ...
                        'Output', 'onset_plus_duration');

  % WHEN
  new_content = bids.transformers.sum(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.onset_plus_duration, [4; 6; 8; 10]);

  % GIVEN
  transformers = struct('Name', 'Sum', ...
                        'Input', {{'onset', 'duration'}}, ...
                        'Weights', [2, 1], ...
                        'Output', 'onset_plus_duration_with_weight');

  % WHEN
  new_content = bids.transformers.sum(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.onset_plus_duration_with_weight, [6; 10; 14; 18]);

end

function test_product()

  % GIVEN
  transformers = struct('Name', 'Product', ...
                        'Input', {{'onset', 'duration'}}, ...
                        'Output', 'onset_times_duration');

  % WHEN
  new_content = bids.transformers.product(transformers, vis_motion_to_threshold_events());

  % THEN
  assertEqual(new_content.onset_times_duration, [4; 8; 12; 16]);

end

function test_scale()

  %% GIVEN
  transformers = struct('Name', 'Factor', ...
                        'Input', {{'age'}});

  % WHEN
  new_content = bids.transformers.scale(transformers, participants());

  % THEN
  assertElementsAlmostEqual(new_content.age, ...
                            [-0.1769; -0.3699; 1.4315; -0.8846; nan], ...
                            'absolute', 1e-3);

  %% GIVEN
  transformers = struct('Name', 'Factor', ...
                        'Input', {{'age'}}, ...
                        'Demean', true, ...
                        'Rescale', true, ...
                        'ReplaceNa', 'off', ...
                        'Output', {{'age_demeaned_centered'}});

  % WHEN
  new_content = bids.transformers.scale(transformers, participants());

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
  new_content = bids.transformers(participants(), transformers);

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
  new_content = bids.transformers(participants(), transformers);

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

function test_drop_na()

  % GIVEN
  transformers = struct('Name', 'Factor', ...
                        'Input', {{'age', 'handedness'}});

  % WHEN
  new_content = bids.transformers.drop_na(transformers, participants());

  % THEN
  assertEqual(new_content.age,  [21; 18; 46; 10]);
  assertEqual(new_content.handedness,  {'right'; 'left'; 'left'; 'right'});

end

%% Helper functions

function value = participants()

  value.sex_m = [true; true; false; false; false];
  value.handedness = {'right'; 'left'; nan; 'left'; 'right'};
  value.sex = {'M'; 'M'; 'F'; 'F'; 'F'};
  value.age_gt_twenty = [true; false; true; false; false];
  value.age = [21; 18; 46; 10; nan];

end

function value = face_rep_events()

  value.onset = [2; 4; 5; 8];
  value.duration = [2; 2; 2; 2];
  value.repetition = [1; 1; 2; 2];
  value.familiarity = {'Famous face'; 'Unfamiliar face'; 'Famous face'; 'Unfamiliar face'};
  value.trial_type = {'Face'; 'Face'; 'Face'; 'Face'};
  value.response_time = [1.5; 2; 1.56; 2.1];

end

function value = vis_motion_events()

  value.onset = [2; 4];
  value.duration = [2; 2];
  value.trial_type = {'VisMot'; 'VisStat'};
  value.intensity = [2; -4];

end

function value = vis_motion_to_threshold_events()

  value.onset = [2; 4; 6; 8];
  value.duration = [2; 2; 2; 2];
  value.trial_type = {'VisMot'; 'VisStat'; 'VisMot'; 'VisStat'};
  value.to_threshold = [1; 2; -1; -2];

end

function cfg = set_up()
  cfg = set_test_cfg();
  cfg.this_path = fileparts(mfilename('fullpath'));
end

function value = dummy_data_dir()
  cfg = set_up();
  value = fullfile(cfg.this_path, 'data', 'tsv_files');
end
