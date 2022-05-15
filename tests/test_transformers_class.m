function test_suite = test_transformers_class %#ok<*STOUT>
  %
  % (C) Copyright 2022 Remi Gau

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end

  initTestSuite;

end

function test_transformers_class_get_output()

  transformer = struct('Input', {{'onset'}});
  bt = bids.transformers.BaseTransformer(transformer);
  assertEqual(bt.input, {'onset'});
  assertEqual(bt.output, {'onset'});

end

function test_transformers_class_base()

  bt = bids.transformers.BaseTransformer();

end

function test_transformers_class_get_input()

  bt = bids.transformers.BaseTransformer();
  assert(isempty(bt.get_input()));

  bt.input = bt.get_input(struct('Input', {{'onset', 'foo', 'bar'}}));
  assertEqual(bt.input, {'onset', 'foo', 'bar'});

  bt = bids.transformers.BaseTransformer(struct('Input', {{'onset', 'foo', 'bar'}}));
  assertEqual(bt.input, {'onset', 'foo', 'bar'});

end

function test_transformers_class_check_input()

  transformer = struct('Input', {{'onset', 'foo', 'bar'}});
  data = vis_motion_to_threshold_events();
  assertExceptionThrown(@()bids.transformers.BaseTransformer(transformer, data), ...
                        'BaseTransformer:missingInput');

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

  value.onset = [2; 4];
  value.duration = [2; 2];
  value.repetition = [1; 1; 2; 2];
  value.familiarity = {'Famous face'; 'Unfamiliar face'; 'Famous face'; 'Unfamiliar face'};
  value.trial_type = {'Face'; 'Face'; 'Face'; 'Face'};

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
