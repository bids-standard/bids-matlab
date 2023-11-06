function test_suite = test_transformers_side_functions %#ok<*STOUT>
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

  [new_content, json] = bids.transformers(transformers, participants());

  assertEqual(new_content, participants());

  assertEqual(json, struct('Transformer', ['bids-matlab_' bids.internal.get_version], ...
                           'Instructions', struct([])));

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
  transformers = struct('Input', {{'onset', 'foo', 'bar'}}, 'tolerant', false);
  data = vis_motion_to_threshold_events();

  % WHEN
  assertExceptionThrown(@()bids.transformers_list.get_input(transformers, data), ...
                        'check_field:missingInput');

end

function status = test_is_run_level()

  data = struct('onset', [], 'duration', [], 'foo', 'bar');
  assert(bids.transformers.is_run_level(data));

end

function test_get_query()

  transformer.Query = 'R T == 1';

  [left, type, right] = bids.transformers_list.get_query(transformer);

  assertEqual(type, '==');
  assertEqual(left, 'R T');
  assertEqual(right, '1');

end
