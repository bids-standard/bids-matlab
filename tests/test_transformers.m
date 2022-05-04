function test_suite = test_transformers %#ok<*STOUT>
  %
  % (C) Copyright 2022 Remi Gau

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end

  initTestSuite;

end

function test_transformers_concatenate()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), ...
                     'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers{1} = struct('Name', 'Concatenate', ...
                           'Input', {{'face_type', 'repetition_type'}}, ...
                           'Output', 'trial_type');

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  assertEqual(unique(new_content.trial_type), ...
              {'famous_1'; 'famous_2';  'unfamiliar_1'; 'unfamiliar_2'});

end

function test_transformers_combine_columns()

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

  clean_up();

end

function test_transformers_touch()

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
                           'Input', {{'tmp', 'Famous', 'FirstRep'}});

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(fieldnames(tsv_content), fieldnames(new_content));

  clean_up();

end

function test_transformers_replace_with_output()

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
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(unique(new_content.tmp), 1);

end

function test_transformers_replace()

  %% GIVEN
  tsvFile = fullfile(dummy_data_dir(), ...
                     'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers(1).Name = 'Replace';
  transformers(1).Input = 'face_type';
  transformers(1).Replace = struct('famous', 'foo');

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(unique(new_content.face_type), {'foo'; 'unfamiliar'});

  %% GIVEN
  transformers(1).Name = 'Replace';
  transformers(1).Input = 'face_type';
  transformers(1).Replace = struct('duration_0', 1);
  transformers(1).Attribute = 'duration';

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(unique(new_content.duration), 1);

end

function test_transformers_add_subtract

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-vismotion_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers(1).Name = 'Subtract';
  transformers(1).Input = 'onset';
  transformers(1).Value = 3;

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(new_content.onset, [-1; 1]);

  clean_up();

end

function test_transformers_add_subtract_with_output

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-vismotion_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers(1).Name = 'Subtract';
  transformers(1).Input = 'onset';
  transformers(1).Value = 3;
  transformers(1).Output = 'onset_minus_3';

  transformers(2).Name = 'Add';
  transformers(2).Input = 'onset';
  transformers(2).Value  = 1;
  transformers(2).Output  = 'onset_plus_1';

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assert(all(ismember({'onset_plus_1'; 'onset_minus_3'}, fieldnames(new_content))));
  assertEqual(new_content.onset_plus_1, [3; 5]);
  assertEqual(new_content.onset_minus_3, [-1; 1]);

  clean_up();

end

function test_transformers_copy()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Copy', ...
                        'Input', {{'face_type', 'repetition_type'}}, ...
                        'Output', {{'foo', 'bar'}});
  new_content = bids.transformers(tsv_content, transformers);

  assert(all(ismember({'foo'; 'bar'}, fieldnames(new_content))));
  assertEqual(new_content.foo, new_content.face_type);
  assertEqual(new_content.bar, new_content.repetition_type);

end

function test_transformers_constant()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), ...
                     'sub-01_task-vismotionForThreshold_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers{1} = struct('Name', 'Constant', ...
                           'Output', 'cst');

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  assertEqual(new_content.cst, ones(4, 1));

  transformers{1} = struct('Name', 'Constant', ...
                           'Value', 2, ...
                           'Output', 'cst');

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  assertEqual(new_content.cst, ones(4, 1) * 2);

end

function test_transformers_filter_by()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers{1} = struct('Name', 'Filter', ...
                           'Input', 'face_type', ...
                           'Query', 'repetition_type==1', ...
                           'By', 'repetition_type', ...
                           'Output', 'face_type_repetition_1');

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  % TODO

end

function test_transformers_threshold_output()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), ...
                     'sub-01_task-vismotionForThreshold_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Output', 'tmp');
  new_content = bids.transformers(tsv_content, transformers);

  assertEqual(new_content.tmp, [1; 2; 0; 0]);

end

function test_transformers_threshold()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), ...
                     'sub-01_task-vismotionForThreshold_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  % WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold');
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(new_content.to_threshold, [1; 2; 0; 0]);

  % WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Threshold', 1);
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(new_content.to_threshold, [0; 2; 0; 0]);

  % WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Binarize', true);
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(new_content.to_threshold, [1; 1; 0; 0]);

  % WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Binarize', true, ...
                        'Above', false);
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(new_content.to_threshold, [0; 0; 1; 1]);

  % WHEN
  transformers = struct('Name', 'Threshold', ...
                        'Input', 'to_threshold', ...
                        'Threshold', 1, ...
                        'Binarize', true, ...
                        'Above', true, ...
                        'Signed', false);
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(new_content.to_threshold, [0; 1; 0; 1]);

end

function test_transformers_delete_select()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Delete', ...
                        'Input', 'face_type');
  new_content = bids.transformers(tsv_content, transformers);

  assert(~(ismember({'face_type'}, fieldnames(new_content))));

  transformers = struct('Name', 'Select', ...
                        'Input', 'face_type');
  new_content = bids.transformers(tsv_content, transformers);

  assertEqual({'face_type'}, fieldnames(new_content));

end

function test_transformers_rename()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionBefore_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Rename', ...
                        'Input', {{'face_type', 'repetition_type'}}, ...
                        'Output', {{'foo', 'bar'}});
  new_content = bids.transformers(tsv_content, transformers);

  assert(all(ismember({'foo'; 'bar'}, fieldnames(new_content))));
  assert(all(~ismember({'face_type'; 'repetition_type'}, fieldnames(new_content))));
  assertEqual(new_content.foo, tsv_content.face_type);
  assertEqual(new_content.bar, tsv_content.repetition_type);

end

function test_transformers_complex_filter_with_and()

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

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assert(all(ismember({'Famous'; 'FirstRep'}, fieldnames(new_content))));
  assertEqual(sum(strcmp(new_content.Famous, 'famous')), 52);
  assertEqual(unique(new_content.Famous), {''; 'famous'});
  assertEqual(nansum(new_content.FirstRep), 52);

  % GIVEN
  transformers{3} = struct('Name', 'And', ...
                           'Input', {{'Famous', 'FirstRep'}}, ...
                           'Output', 'FamousFirstRep');

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assertEqual(sum(new_content.FamousFirstRep), 26);

  clean_up();

end

function test_transformers_filter()

  % GIVEN
  tsvFile = fullfile(dummy_data_dir(), 'sub-01_task-FaceRepetitionAfter_events.tsv');
  tsv_content = bids.util.tsvread(tsvFile);

  transformers = struct('Name', 'Filter', ...
                        'Input', 'trial_type', ...
                        'Query', 'trial_type==F1', ...
                        'Output', 'Famous_1');

  % WHEN
  new_content = bids.transformers(tsv_content, transformers);

  % THEN
  assert(all(ismember({'Famous_1'}, fieldnames(new_content))));
  assertEqual(numel(new_content.Famous_1), 104);
  assertEqual(unique(new_content.Famous_1), {''; 'F1'});

  clean_up();

end

function test_transformers_no_transformation()

end

function cfg = set_up()
  cfg = set_test_cfg();
  cfg.this_path = fileparts(mfilename('fullpath'));
end

function clean_up()

end

function value = dummy_data_dir()
  cfg = set_up();
  value = fullfile(cfg.this_path, 'data', 'tsv_files');
end
