% (C) Copyright 2020 CPP_SPM developers

function test_suite = test_bids_model %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_model_basic()

  bm = bids.Model('file', model_file('narps'));

  assertEqual(bm.Name, 'NARPS');
  assertEqual(bm.Description, 'NARPS Analysis model');
  assertEqual(bm.BIDSModelVersion, '1.0.0');
  assertEqual(bm.Input, struct('task', 'MGT'));
  assertEqual(numel(bm.Nodes), 5);
  assertEqual(numel(bm.Edges), 4);
  assertEqual(bm.Edges{1}, struct('Source', 'run', 'Destination', 'subject'));

end

function test_model_write()

  bm = bids.Model('file', model_file('narps'));

  filename = fullfile(pwd, 'tmp', 'foo.json');
  bm.write(filename);
  assertEqual(bids.util.jsondecode(model_file('narps')), ...
              bids.util.jsondecode(filename));

  delete(filename);

end

function test_model_get_nodes()

  bm = bids.Model('file', model_file('narps'));

  assertEqual(numel(bm.get_nodes), 5);
  assertEqual(numel(bm.get_nodes('Level', 'Run')), 1);
  assertEqual(numel(bm.get_nodes('Level', 'Dataset')), 3);
  assertEqual(numel(bm.get_nodes('Name', 'negative')), 1);

  assertWarning(@()bm.get_nodes('Name', 'foo'), 'Model:missingNode');

end

function test_model_get_design_matrix()

  bm = bids.Model('file', model_file('narps'));

  assertEqual(bm.get_design_matrix('Name', 'run'), ...
              {'trials'
               'gain'
               'loss'
               'demeaned_RT'
               1});

end

function test_model_node_level_getters()

  bm = bids.Model('file', model_file('narps'));

  assertEqual(bm.get_dummy_contrasts('Name', 'run'), ...
              struct('Contrasts', {{'gain'; 'loss'}}, ...
                     'Test', 't'));

  assertEqual(fieldnames(bm.get_transformations('Name', 'run')), ...
              {'Transformer';  'Instructions'});

  assertEqual(bm.get_contrasts('Name', 'positive'), ...
              struct('Name', 'positive', 'ConditionList', 1, 'Weights', 1, 'Test', 't'));

end

function test_model_empty_model()

  bm = bids.Model('init', true);
  filename = fullfile(pwd, 'tmp', 'foo.json');
  bm.write(filename);
  assertEqual(bids.util.jsondecode(filename), ...
              bids.util.jsondecode(model_file('empty')));
  delete(filename);

end

function test_model_default_model()

  if bids.internal.is_octave() && bids.internal.is_github_ci()
    % TODO fix for octave in CI
    return
  end

  pth_bids_example = get_test_data_dir();
  BIDS = bids.layout(fullfile(pth_bids_example, 'ds003'));

  bm = bids.Model();
  bm = bm.default(BIDS);

  filename = fullfile(pwd, 'tmp', 'rhymejudgement.json');
  bm.write(filename);

  assertEqual(bids.util.jsondecode(filename), ...
              bids.util.jsondecode(model_file('rhymejudgement')));
  delete(filename);

end

function value = model_file(name)
  value = fullfile(get_test_data_dir(), '..', 'data', 'model', ['model-' name '_smdl.json']);
end
