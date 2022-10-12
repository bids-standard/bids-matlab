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
  bt = bids.transformers_list.BaseTransformer(transformer);
  assertEqual(bt.input, {'onset'});
  assertEqual(bt.output, {'onset'});

end

function test_transformers_class_base()

  bt = bids.transformers_list.BaseTransformer();

end

function test_transformers_class_get_input()

  bt = bids.transformers_list.BaseTransformer();
  assert(isempty(bt.get_input()));

  bt.input = bt.get_input(struct('Input', {{'onset', 'foo', 'bar'}}));
  assertEqual(bt.input, {'onset', 'foo', 'bar'});

  bt = bids.transformers_list.BaseTransformer(struct('Input', {{'onset', 'foo', 'bar'}}));
  assertEqual(bt.input, {'onset', 'foo', 'bar'});

end

function test_transformers_class_check_input()

  transformer = struct('Input', {{'onset', 'foo', 'bar'}});
  data = vis_motion_to_threshold_events();
  assertExceptionThrown(@()bids.transformers_list.BaseTransformer(transformer, data), ...
                        'BaseTransformer:missingInput');

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
