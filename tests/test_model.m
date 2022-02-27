% (C) Copyright 2020 CPP_SPM developers

function test_suite = test_model %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_model_basic()

  opt = setOptions('narps');

  bm = Model('file', opt.model.file);

  assertEqual(bm.Name, 'NARPS');
  assertEqual(bm.Description, 'NARPS Analysis model');
  assertEqual(bm.BIDSModelVersion, '1.0.0');
  assertEqual(bm.Input, struct('task', 'MGT'));
  assertEqual(numel(bm.Nodes), 5);
  assertEqual(numel(bm.Edges), 4);
  assertEqual(bm.Edges{1}, struct('Source', 'run', 'Destination', 'subject'));

end

function test_model_write()

  opt = setOptions('narps');

  bm = Model('file', opt.model.file);

  filename = fullfile(pwd, 'tmp', 'foo.json');
  bm.write(filename);
  assertEqual(bids.util.jsondecode(opt.model.file), ...
              bids.util.jsondecode(filename));

  delete(filename);

end

function test_model_get_nodes()

  opt = setOptions('narps');

  bm = Model('file', opt.model.file);

  assertEqual(numel(bm.get_nodes), 5);
  assertEqual(numel(bm.get_nodes('Level', 'Run')), 1);
  assertEqual(numel(bm.get_nodes('Level', 'Dataset')), 3);
  assertEqual(numel(bm.get_nodes('Name', 'negative')), 1);

  assertWarning(@()bm.get_nodes('Name', 'foo'), 'Model:missingNode');

end

function test_model_get_design_matrix()

  opt = setOptions('narps');

  bm = Model('file', opt.model.file);

  assertEqual(bm.get_design_matrix('Name', 'run'), ...
              {'trials'
               'gain'
               'loss'
               'demeaned_RT'
               1});

end

function test_model_node_level_getters()

  opt = setOptions('narps');

  bm = Model('file', opt.model.file);

  assertEqual(bm.get_dummy_contrasts('Name', 'run'), ...
              struct('Conditions', {{'gain'; 'loss'}}, ...
                     'Test', 't'));

  assertEqual(fieldnames(bm.get_transformations('Name', 'run')), ...
              {'Transformer';  'Instructions'});

  assertEqual(bm.get_contrasts('Name', 'positive'), ...
              struct('Name', 'positive', 'ConditionList', 1, 'Weights', 1, 'Test', 't'));

end

function test_model_empty_model()

  bm = Model('init', true);
  bm.write('tmp.json');
  assertEqual(bids.util.jsondecode('tmp.json'), ...
              bids.util.jsondecode('empty.json'));

end
