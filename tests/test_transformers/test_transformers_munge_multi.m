function test_suite = test_transformers_munge_multi %#ok<*STOUT>
  %

  % (C) Copyright 2022 Remi Gau

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end

  initTestSuite;

end

%% MUNGE

%% multi step

function test_multi_touch()

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
  [new_content, json] = bids.transformers(transformers, tsv_content);

  % THEN
  % TODO assert whole content
  assertEqual(fieldnames(tsv_content), fieldnames(new_content));
  assertEqual(json, struct('Transformer', ['bids-matlab_' bids.internal.get_version], ...
                           'Instructions', {transformers}));

end

function test_multi_combine_columns()

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
  data = tsv_content;
  new_content = bids.transformers(transformers, data);

  % THEN
  % TODO assert whole content
  assertEqual(fieldnames(tsv_content), fieldnames(new_content));
  assertEqual(unique(new_content.trial_type), {'face'});

end

function test_multi_complex_filter_with_and()

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
  data = tsv_content;
  new_content = bids.transformers(transformers, data);

  % THEN
  assert(all(ismember({'Famous'; 'FirstRep'}, fieldnames(new_content))));
  assertEqual(sum(strcmp(new_content.Famous, 'famous')), 52);

  if ~isempty(which('nansum'))
    assertEqual(bids.internal.nansum(new_content.FirstRep), 52);
  end

  %% GIVEN
  transformers{3} = struct('Name', 'And', ...
                           'Input', {{'Famous', 'FirstRep'}}, ...
                           'Output', 'FamousFirstRep');

  % WHEN
  data = tsv_content;
  new_content = bids.transformers(transformers, data);

  % THEN
  assertEqual(sum(new_content.FamousFirstRep), 26);

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
