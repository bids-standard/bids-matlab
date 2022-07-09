function test_suite = test_transformers_munge %#ok<*STOUT>
  %
  % (C) Copyright 2022 Remi Gau

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end

  initTestSuite;

end

%%

function test_no_transformation()

  transformers = struct([]);

  new_content = bids.transformers(transformers, participants());

  assertEqual(new_content, participants());

end

%% SIDE FUNCTIONS

function test_get_input()

  %% GIVEN
  transformers = struct('Input', {{'onset'}});
  data = vis_motion_to_threshold_events();

  % WHEN
  inputs = bids.transformers_list.get_input(transformers, data);

  assertEqual(inputs, {'onset'});

  %% GIVEN
  transformers = struct('Input', {{'onset', 'foo', 'bar'}});
  data = vis_motion_to_threshold_events();

  % WHEN
  assertExceptionThrown(@()bids.transformers_list.get_input(transformers, data), ...
                        'check_field:missingInput');

end

function status = test_is_run_level()

  data = struct('onset', [], 'duration', [], 'foo', 'bar');
  assert(bids.transfomers.is_run_level(data));

end

function test_get_query()

  transformer.Query = 'R T == 1';

  [left, type, right] = bids.transformers_list.get_query(transformer);

  assertEqual(type, '==');
  assertEqual(left, 'R T');
  assertEqual(right, '1');

end

%% LOGICAL

function test_and()

  % GIVEN
  transformers = struct('Name', 'And', ...
                        'Input', {{'sex_m', 'age_gt_twenty'}}, ...
                        'Output', 'men_gt_twenty');

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content.men_gt_twenty, [true; false; false; false; false]);

end

function test_and_nan()

  % GIVEN
  transformers = struct('Name', 'And', ...
                        'Input', {{'handedness', 'age'}}, ...
                        'Output', 'age_or_hand');

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content.age_or_hand, [true; true; false; true; false]);

end

function test_or()

  % GIVEN
  transformers = struct('Name', 'Or', ...
                        'Input', {{'sex_m', 'age_gt_twenty'}}, ...
                        'Output', 'men_or_gt_twenty');

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content.men_or_gt_twenty, [true; true; true; false; false]);

end

function test_not()

  % GIVEN
  transformers = struct('Name', 'Not', ...
                        'Input', {{'age_gt_twenty'}}, ...
                        'Output', 'ager_lt_twenty');

  % WHEN
  new_content = bids.transformers(transformers, participants());

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
                           'Replace', struct('key', 1, ...
                                             'value', 1));
  transformers{3} = struct('Name', 'Delete', ...
                           'Input', {{'tmp'}});

  % WHEN
  new_content = bids.transformers(transformers, tsv_content);

  % THEN
  % TODO assert whole content
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
                           'Replace', struct('key', 'tmp_1', ...
                                             'value', 'FamousFirstRep'));
  transformers{5} = struct('Name', 'Delete', ...
                           'Input', {{'tmp', 'Famous', 'FirstRep'}});

  % WHEN
  new_content = bids.transformers(transformers, tsv_content);

  % THEN
  % TODO assert whole content
  assertEqual(fieldnames(tsv_content), fieldnames(new_content));
  assertEqual(unique(new_content.trial_type), {'face'});

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
  new_content = bids.transformers(transformers, tsv_content);

  % THEN
  assert(all(ismember({'Famous'; 'FirstRep'}, fieldnames(new_content))));
  assertEqual(sum(strcmp(new_content.Famous, 'famous')), 52);
  if ~bids.internal.is_octave
    assertEqual(nansum(new_content.FirstRep), 52);
  end

  %% GIVEN
  transformers{3} = struct('Name', 'And', ...
                           'Input', {{'Famous', 'FirstRep'}}, ...
                           'Output', 'FamousFirstRep');

  % WHEN
  new_content = bids.transformers(transformers, tsv_content);

  % THEN
  assertEqual(sum(new_content.FamousFirstRep), 26);

end

%% single step

% ordered alphabetically

function test_assign_with_target_attribute()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face', ...
                        'TargetAttr', 'duration');

  data = face_rep_events();
  data.Face = [1; 1; 1; 1];

  new_content = bids.transformers(transformers, data);

  % check non involved fields are padded correctly
  expected.familiarity = cat(1, data.familiarity, repmat({nan}, 4, 1));
  expected.onset = [data.onset; data.onset];

  assertEqual(new_content.familiarity, expected.familiarity);
  assertEqual(new_content.onset, expected.onset);

  % check involved fields
  expected.response_time = [data.response_time; nan(size(data.response_time))];
  expected.Face = [nan(size(data.response_time)); data.Face];
  expected.duration = [data.duration; data.response_time];

  assertEqual(new_content.response_time, expected.response_time);
  assertEqual(new_content.Face, expected.Face);
  assertEqual(new_content.duration, expected.duration);

end

function test_assign()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face');

  data = face_rep_events();
  data.Face = [1; 1; 1; 1];

  new_content = bids.transformers(transformers, data);

  assertEqual(new_content.Face, new_content.response_time);

end

function test_assign_with_output()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face', ...
                        'Output', 'new_face');

  data = face_rep_events();
  data.Face = [1; 1; 1; 1];

  new_content = bids.transformers(transformers, data);

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

  new_content = bids.transformers(transformers, data);

  assertEqual(new_content.new_face, new_content.onset);

end

function test_assign_missing_target()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face');

  assertExceptionThrown(@()bids.transformers(transformers, face_rep_events()), ...
                        'check_field:missingTarget');

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
  new_content = bids.transformers(transformers, tsv_content);

  assertEqual(unique(new_content.trial_type), ...
              {'famous_1'; 'famous_2';  'unfamiliar_1'; 'unfamiliar_2'});

end

function test_concatenate_strings()

  % GIVEN
  transformers = struct('Name', 'Concatenate', ...
                        'Input', {{'trial_type', 'familiarity'}}, ...
                        'Output', 'trial_type');

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  assertEqual(unique(new_content.trial_type), ...
              {'Face_Famous face'; ...
               'Face_Unfamiliar face'});

end

function test_concatenate_numbers()

  % GIVEN
  transformers = struct('Name', 'Concatenate', ...
                        'Input', {{'onset', 'response_time'}}, ...
                        'Output', 'trial_type');

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  assertEqual(unique(new_content.trial_type), ...
              {'2_1.5'
               '4_2'
               '5_1.56'
               '8_2.1'});

end

function test_copy()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Copy', ...
                        'Input', {{'face_type', 'repetition_type'}}, ...
                        'Output', {{'foo', 'bar'}});
  new_content = bids.transformers(transformers, tsv_content);

  assert(all(ismember({'foo'; 'bar'}, fieldnames(new_content))));
  assertEqual(new_content.foo, new_content.face_type);
  assertEqual(new_content.bar, new_content.repetition_type);

end

function test_delete_select()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Delete', ...
                        'Input', 'face_type');

  new_content = bids.transformers(transformers, tsv_content);

  assert(~(ismember({'face_type'}, fieldnames(new_content))));

  % GIVEN
  transformers = struct('Name', 'Select', ...
                        'Input', 'face_type');

  new_content = bids.transformers(transformers, tsv_content);

  assertEqual(fieldnames(new_content), {    'face_type'
                                        'onset'
                                        'duration'});

end

function test_drop_na()

  % GIVEN
  transformers = struct('Name', 'DropNA', ...
                        'Input', {{'age', 'handedness'}});

  % WHEN
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content.age,  [21; 18; 46; 10]);
  assertEqual(new_content.handedness,  {'right'; 'left'; 'left'; 'right'});

end

function test_factor()

  % GIVEN
  transformers = struct('Name', 'Factor', ...
                        'Input', {{'familiarity'}});

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

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
  new_content = bids.transformers(transformers, participants());

  % THEN
  assert(isfield(new_content, 'age_10'));
  assert(isfield(new_content, 'age_NaN'));
  assertEqual(new_content.age_10,  [false; false; false; true; false]);
  assertEqual(new_content.age_NaN,  [false; false; false; false; true]);

end

function test_filter_numeric()

  types = {'>=', '<=', '==', '>', '<'};
  expected = [nan 2 1.56 2.1
              1.5 nan 1.56 nan
              nan nan 1.56 nan
              nan 2 nan 2.1
              1.5 nan nan nan];

  for i = 1:numel(types)

    % GIVEN
    transformers = struct('Name', 'Filter', ...
                          'Input', 'response_time', ...
                          'Query', [' response_time ' types{i} ' 1.56']);

    % WHEN
    new_content = bids.transformers(transformers, face_rep_events());

    % THEN
    types{i};
    assertEqual(new_content.response_time, expected(i, :)');

  end

end

function test_filter_string()

  % GIVEN
  transformers = struct('Name', 'Filter', ...
                        'Input', 'familiarity', ...
                        'Query', ' familiarity == Famous face ');

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  % THEN
  assertEqual(new_content.familiarity, {'Famous face'; nan; 'Famous face'; nan});

end

function test_filter_string_output()

  % GIVEN
  transformers = struct('Name', 'Filter', ...
                        'Input', 'familiarity', ...
                        'Query', ' familiarity == Famous face ', ...
                        'Output', 'famous_face');

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  % THEN
  assertEqual(new_content.familiarity, {'Famous face'
                                        'Unfamiliar face'
                                        'Famous face'
                                        'Unfamiliar face'});
  assertEqual(new_content.famous_face, {'Famous face'; nan'; 'Famous face'; nan});

end

function test_filter_string_output_across_columns()

  % GIVEN
  transformers = struct('Name', 'Filter', ...
                        'Input', 'onset', ...
                        'Query', ' familiarity == Famous face ', ...
                        'Output', 'new');

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  % THEN
  assertEqual(new_content.new, [2; nan; 5; nan]);

end

function test_filter_across_columns()

  transformers = struct('Name', 'Filter', ...
                        'Input', 'familiarity', ...
                        'Query', 'repetition==1', ....
                        'Output', 'familiarity_repetition_1');

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events);

  % THEN
  assertEqual(new_content.familiarity_repetition_1, ...
              {'Famous face'; 'Unfamiliar face'; nan; nan});

end

function test_filter_several_inputs()

  transformers = struct('Name', 'Filter', ...
                        'Input', {{'repetition', 'response_time'}}, ...
                        'Query', 'repetition>1');

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events);

  assertEqual(new_content.repetition, [nan; nan; 2; 2]);

  assertEqual(new_content.response_time, [nan; nan; 1.56; 2.1]);

end

function test_label_identical_rows

  transformers(1).Name = 'LabelIdenticalRows';
  transformers(1).Input = {'trial_type', 'stim_type'};

  data.trial_type = {'face'; 'face'; 'house'; 'house'; 'house'; 'house'; 'house'; 'chair'};
  data.stim_type =  [1; 1; 1; 2; nan; 5; 2; nan];

  new_content = bids.transformers(transformers, data);

  assertEqual(new_content.trial_type_label, [1; 2; 1; 2; 3; 4; 5; 1]);
  assertEqual(new_content.stim_type_label,  [1; 2; 3; 1; 1; 1; 1; 1]);

end

function test_label_identical_rows_cumulative

  transformers(1).Name = 'LabelIdenticalRows';
  transformers(1).Input = {'trial_type'};
  transformers(1).Cumulative = true;

  data.trial_type = {'face'; 'face'; 'house'; 'house'; 'face'; 'house'; 'chair'};

  new_content = bids.transformers(transformers, data);

  assertEqual(new_content.trial_type_label, [1; 2; 1; 2; 3; 3; 1]);

end

function test_merge_identical_rows

  transformers(1).Name = 'MergeIdenticalRows';
  transformers(1).Input = {'trial_type'};

  data.trial_type = {'house'; 'face'; 'face'; 'house'; 'chair'; 'house'; 'chair'};
  data.duration =   [1; 1; 1; 1; 1; 1; 1];
  data.onset =      [3; 1; 2; 6; 8; 4; 7];
  data.stim_type =  {'delete'; 'delete'; 'keep'; 'keep'; 'keep'; 'delete'; 'delete'};

  new_content = bids.transformers(transformers, data);

  assertEqual(new_content.trial_type, {'face'; 'house'; 'chair'});
  assertEqual(new_content.stim_type, {'keep'; 'keep'; 'keep'});
  assertEqual(new_content.onset,     [1; 3; 7]);
  assertEqual(new_content.duration,  [2; 4; 2]);

end

function test_replace()

  %% GIVEN
  transformers(1).Name = 'Replace';
  transformers(1).Input = 'familiarity';
  transformers(1).Replace(1) = struct('key', 'Famous face', 'value', 'foo');
  transformers(1).Replace(2) = struct('key', 'Unfamiliar face', 'value', 'bar');

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  % THEN
  assertEqual(new_content.familiarity, {'foo'; 'bar'; 'foo'; 'bar'});

end

function test_replace_string_by_numeric()

  %% GIVEN
  transformers(1).Name = 'Replace';
  transformers(1).Input = 'familiarity';
  transformers(1).Replace(1).key = 'Famous face';
  transformers(1).Replace(1).value = 1;
  transformers(1).Attribute = 'duration';

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  % THEN
  assertEqual(new_content.duration, [1; 2; 1; 2]);

end

function test_replace_with_output()

  %% GIVEN
  transformers(1).Name = 'Replace';
  transformers(1).Input = 'familiarity';
  transformers(1).Output = 'tmp';
  transformers(1).Replace(1).key = 'Famous face';
  transformers(1).Replace(1).value = 1;
  transformers(1).Attribute = 'all';

  % WHEN
  new_content = bids.transformers(transformers, face_rep_events());

  % THEN
  assertEqual(new_content.tmp, {1; 'Unfamiliar face'; 1; 'Unfamiliar face'});
  assertEqual(new_content.duration, [1; 2; 1; 2]);
  assertEqual(new_content.onset, [1; 4; 1; 8]);

end

function test_replace_string_in_numeric_output()

  %% GIVEN
  data.fruits = {'apple'; 'banana'; 'elusive'};
  data.onset = {1; 2; 3};
  data.duration = {0; 1; 3};

  replace = struct('key', {'apple'; 'elusive'}, 'value', -1);
  replace(end + 1).key = -1;
  replace(end).value = 0;

  transformer = struct('Name', 'Replace', ...
                       'Input', 'fruits', ...
                       'Attribute', 'all', ...
                       'Replace', replace);

  % WHEN
  new_content = bids.transformers(transformer, data);

  % THEN
  assertEqual(new_content.fruits, {0; 'banana'; 0});
  assertEqual(new_content.onset,  {0; 2; 0});
  assertEqual(new_content.duration,  {0; 1; 0});

end

function test_rename()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Rename', ...
                        'Input', {{'face_type', 'repetition_type'}}, ...
                        'Output', {{'foo', 'bar'}});
  new_content = bids.transformers(transformers, tsv_content);

  assert(all(ismember({'foo'; 'bar'}, fieldnames(new_content))));
  assert(all(~ismember({'face_type'; 'repetition_type'}, fieldnames(new_content))));
  assertEqual(new_content.foo, tsv_content.face_type);
  assertEqual(new_content.bar, tsv_content.repetition_type);

end

function test_select()

  % GIVEN
  transformers = struct('Name', 'Select', ...
                        'Input', {{'age'}});

  % WHEN'
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(fieldnames(new_content), {'age'});

end

function test_select_event()

  % GIVEN
  transformers = struct('Name', 'Select', ...
                        'Input', {{'familiarity'}});

  % WHEN'
  new_content = bids.transformers(transformers, face_rep_events());

  % THEN
  assertEqual(fieldnames(new_content), {'familiarity'; 'onset'; 'duration'});

end

function test_split_empty_by()

  % GIVEN
  transformers = struct('Name', 'Split', ...
                        'Input', {{'age'}}, ...
                        'By', {{}});

  % WHEN'
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content, participants);

end

function test_split_simple()

  % GIVEN
  transformers = struct('Name', 'Split', ...
                        'Input', {{'age'}}, ...
                        'By', {{'sex'}});

  % WHEN'
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content.age_BY_sex_M,  [21; 18; nan; nan; nan]);
  assertEqual(new_content.age_BY_sex_F,  [nan; nan; 46; 10; nan]);

end

function test_split_simple_string()

  % GIVEN
  transformers = struct('Name', 'Split', ...
                        'Input', {{'handedness'}}, ...
                        'By', {{'sex'}});

  % WHEN'
  new_content = bids.transformers(transformers, participants());

  % THEN
  assertEqual(new_content.handedness_BY_sex_F,  {nan; nan; nan; 'left'; 'right'});
  assertEqual(new_content.handedness_BY_sex_M,  {'right'; 'left'; nan; nan; nan});

end

function test_split_nested()

  % GIVEN
  transformers = struct('Name', 'Split', ...
                        'Input', {{'age'}}, ...
                        'By', {{'sex', 'handedness'}});

  % WHEN'
  new_content = bids.transformers(transformers, participants());

  % THEN
  assert(isfield(new_content, 'age_BY_handedness_left_BY_sex_M'));
  assertEqual(numel(fieldnames(new_content)), 11);
  assertEqual(new_content.age_BY_handedness_left_BY_sex_M,  [NaN; 18; NaN; NaN; NaN]);

end

%% Helper functions

function cfg = set_up()
  cfg = set_test_cfg();
  cfg.this_path = fileparts(mfilename('fullpath'));
end

function value = dummy_data_dir()
  cfg = set_up();
  value = fullfile(cfg.this_path, '..', 'data', 'tsv_files');
end
