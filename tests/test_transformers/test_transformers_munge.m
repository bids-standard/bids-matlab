function test_suite = test_transformers_munge %#ok<*STOUT>
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
  %     write_test_definition_to_file(input, output, trans, test_name, 'munge');

end

%% single step

% ordered alphabetically

function test_Assign_with_target_attribute()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face', ...
                        'TargetAttr', 'duration');

  data = face_rep_events();
  data.Face = [1; 1; 1; 1];

  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

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

function test_Assign_missing_target()

  transformers = struct('Name', 'Assign', ...
                        'Input', 'response_time', ...
                        'Target', 'Face');

  assertExceptionThrown(@()bids.transformers(transformers, face_rep_events()), ...
                        'check_field:missingTarget');

end

function test_Filter_across_columns()

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

function test_Filter_several_inputs()

  transformers = struct('Name', 'Filter', ...
                        'Input', {{'repetition', 'response_time'}}, ...
                        'Query', 'repetition>1');

  % WHEN
  data = face_rep_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  assertEqual(new_content.repetition, [nan; nan; 2; 2]);

  assertEqual(new_content.response_time, [nan; nan; 1.56; 2.1]);

end

function test_Filter_missing_filter_returns_data_unchanged()

  transformers = struct('Name', 'Filter', ...
                        'Input', 'familiarity', ...
                        'Query', 'target < 1');

  % WHEN
  data = face_rep_events();
  new_content = bids.transformers(transformers, data);
  st = dbstack;
  write_definition(data, new_content, transformers, st);

  assertEqual(new_content, data);

end

function test_Replace_string_in_numeric_output()

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

%% Helper functions

function cfg = set_up()
  cfg = set_test_cfg();
  cfg.this_path = fileparts(mfilename('fullpath'));
end

function value = dummy_data_dir()
  cfg = set_up();
  value = fullfile(cfg.this_path, '..', 'data', 'tsv_files');
end
