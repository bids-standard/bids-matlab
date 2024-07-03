function test_suite = test_bids_model %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_build_dag()
  %
  % model is run --> subject --> dataset
  %             \
  %              --> session
  %
  % but nodes and edges and not ordered properly
  %

  bm = bids.Model('init', true);

  bm.Nodes{1} = bm.empty_node('dataset');
  bm.Nodes{4} = bm.empty_node('session');
  bm.Nodes{2} = bm.empty_node('run');
  bm.Nodes{3} = bm.empty_node('subject');

  bm.Edges{1} = struct('Source', 'subject', 'Destination', 'dataset');
  bm.Edges{3} = struct('Source', 'run', 'Destination', 'session');
  bm.Edges{2} = struct('Source', 'run', 'Destination', 'subject');

  bm = bm.build_dag();

  assertEqual(bm.dag_built, true);
  assertEqual(bm.Nodes{1}.parent, 'subject');
  assert(~isfield(bm.Nodes{2}, 'parent'));
  assertEqual(bm.Nodes{3}.parent, 'run');
  assertEqual(bm.Nodes{4}.parent, 'run');

end

function test_model_node_not_in_edges()

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  bm.Nodes{end + 1} = bm.Nodes{end};
  bm.Nodes{end}.Name = 'Foo';

  bm.verbose = true;
  assertWarning(@()bm.validate_edges(), 'Model:nodeMissingFromEdges');

end

function test_model_load_edges()

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  edges = bm.Edges;

  assertEqual(edges{1}, struct('Source', 'run', 'Destination', 'subject'));
  assertEqual(edges{2}, struct('Source', 'subject', 'Destination', 'positive'));
  assertEqual(edges{3}, struct('Source', 'subject', ...
                               'Destination', 'negative-loss', ...
                               'Filter', struct('contrast', {{'loss'}})));
  assertEqual(edges{4}, struct('Source', 'subject', ...
                               'Destination', 'between-groups', ...
                               'Filter', struct('contrast', {{'loss'}})));

end

function test_model_with_edges_and_node_not_in_order()
  %
  % model is run --> subject --> dataset
  %             \
  %              --> session
  %
  % but nodes and edges and not ordered properly
  %

  bm = bids.Model('init', true);

  bm.Nodes{1} = bm.empty_node('dataset');
  bm.Nodes{4} = bm.empty_node('session');
  bm.Nodes{2} = bm.empty_node('run');
  bm.Nodes{3} = bm.empty_node('subject');

  bm.Edges{1} = struct('Source', 'subject', 'Destination', 'dataset');
  bm.Edges{3} = struct('Source', 'run', 'Destination', 'session');
  bm.Edges{2} = struct('Source', 'run', 'Destination', 'subject');

  assertEqual(bm.get_source_node('session'), bm.get_nodes('Name', 'run'));

  [root_node, root_node_name] = bm.get_root_node();
  assertEqual(root_node_name, 'run');

end

function test_model_get_root_node()

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  [root_node, root_node_name] = bm.get_root_node();

  assertEqual(root_node_name, 'run');

end

function test_model_get_source_nodes()

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  assertEqual(bm.get_source_node('run'), {});

  assertEqual(bm.get_source_node('subject'), bm.get_nodes('Name', 'run'));

  assertEqual(bm.get_source_node('negative-loss'), bm.get_nodes('Name', 'subject'));

end

function test_model_get_edge()

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  assertEqual(bm.get_edge('Source', 'run'), struct('Source', 'run', ...
                                                   'Destination', 'subject'));

  assertEqual(numel(bm.get_edge('Source', 'subject')), 3);

  assertEqual(bm.get_edge('Destination', 'negative-loss'), ...
              struct('Source', 'subject', ...
                     'Destination', 'negative-loss', ...
                     'Filter', struct('contrast', {{'loss'}})));

end

function test_model_bug_385()

  bm = bids.Model('file', model_file('bug385'), 'verbose', false);

end

function test_model_basic()

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  assertEqual(bm.Name, 'NARPS');
  assertEqual(bm.Description, 'NARPS Analysis model');
  assertEqual(bm.BIDSModelVersion, '1.0.0');
  assertEqual(bm.Input, struct('task', {{'MGT'}}));
  assertEqual(numel(bm.Nodes), 5);
  assertEqual(numel(bm.Edges), 4);
  assertEqual(bm.Edges{1}, struct('Source', 'run', 'Destination', 'subject'));

end

function test_model_default_model()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds003'));

  bm = bids.Model();
  bm = bm.default(BIDS);

  filename = fullfile(pwd, 'tmp', 'rhymejudgement.json');
  bm.write(filename);

  assertEqual(bids.util.jsondecode(filename), ...
              bids.util.jsondecode(model_file('rhymejudgement')));
  delete(filename);

end

function test_model_default_model_with_nan_trial_type()

  bids_tmp = temp_dir();
  copyfile(fullfile(get_test_data_dir(), 'ds003'), bids_tmp);
  if bids.internal.is_octave
    bids_tmp = fullfile(bids_tmp,  'ds003');
  end

  BIDS = bids.layout(bids_tmp);
  tsv_files = bids.query(BIDS, 'data', 'suffix', 'events');
  content = bids.util.tsvread(tsv_files{1});
  content.trial_type{1} = 'n/a';
  bids.util.tsvwrite(tsv_files{1}, content);

  BIDS = bids.layout(bids_tmp);

  bm = bids.Model();
  bm = bm.default(BIDS);

  %   design matrix should not include n/a
  assertEqual(bm.Nodes{1}.Model.X, ...
              {'trial_type.pseudoword'
               'trial_type.word'
               '1'                    });

end

function test_model_default_no_events()

  pth_bids_example = get_test_data_dir();
  BIDS = bids.layout(fullfile(pth_bids_example, 'asl001'));

  bm = bids.Model('verbose', false);
  bm = bm.default(BIDS);
  assertEqual(bm.Nodes{1}.Model.X, {'1'});

end

function test_model_validate()

  skip_if_octave('mixed-string-concat warning thrown');

  bm = bids.Model();
  bm.Nodes{1} = rmfield(bm.Nodes{1}, 'Name');
  assertWarning(@()bm.validate(), 'Model:missingField');

  bm = bids.Model();
  bm.Nodes{1}.Model = rmfield(bm.Nodes{1}.Model, 'X');
  assertWarning(@()bm.validate(), 'Model:missingField');

  bm.Nodes{1}.Transformations = rmfield(bm.Nodes{1}.Transformations, 'Transformer');
  assertWarning(@()bm.validate(), 'Model:missingField');

  bm.Nodes{1}.Contrasts = rmfield(bm.Nodes{1}.Contrasts{1}, 'ConditionList');
  assertWarning(@()bm.validate(), 'Model:missingField');

end

function test_model_write()

  filename = fullfile(pwd, 'tmp', 'model-foo_smdl.json');

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  bm.write(filename);
  assertEqual(bids.util.jsondecode(model_file('narps')), ...
              bids.util.jsondecode(filename));

  delete(filename);

  bm = bids.Model('file', model_file('bug385'), 'verbose', false);

  bm.write(filename);
  assertEqual(bids.util.jsondecode(model_file('bug385')), ...
              bids.util.jsondecode(filename));

  delete(filename);

end

function test_model_get_nodes()

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  assertEqual(numel(bm.get_nodes), 5);
  assertEqual(numel(bm.get_nodes('Level', '')), 5);
  assertEqual(numel(bm.get_nodes('Name', '')), 5);
  assertEqual(numel(bm.get_nodes('Level', '', 'Name', '')), 5);
  assertEqual(numel(bm.get_nodes('Level', 'Run')), 1);
  assertEqual(numel(bm.get_nodes('Level', 'Dataset')), 3);
  assertEqual(numel(bm.get_nodes('Name', 'negative-loss')), 1);

  bm.verbose = true;
  assertWarning(@()bm.get_nodes('Name', 'foo'), 'Model:missingNode');

end

function test_model_get_design_matrix()

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  assertEqual(bm.get_design_matrix('Name', 'run'), ...
              {'trials'
               'gain'
               'loss'
               'demeaned_RT'
               'rot_x'
               'rot_y'
               'rot_z'
               'trans_x'
               'trans_y'
               'trans_z'
               1});

end

function test_model_node_level_getters()

  bm = bids.Model('file', model_file('narps'), 'verbose', false);

  assertEqual(bm.get_dummy_contrasts('Name', 'run'), ...
              struct('Conditions', {{'trials'; 'gain'; 'loss'}}, ...
                     'Test', 't'));

  assertEqual(fieldnames(bm.get_transformations('Name', 'run')), ...
              {'Transformer';  'Instructions'});

  assertEqual(bm.get_contrasts('Name', 'negative-loss'), ...
              {struct('Name', 'negative', 'ConditionList', 1, 'Weights', -1, 'Test', 't')});

end

function test_model_empty_model()

  bm = bids.Model('init', true);
  filename = fullfile(pwd, 'tmp', 'foo.json');
  bm.write(filename);
  assertEqual(bids.util.jsondecode(filename), ...
              bids.util.jsondecode(model_file('empty')));
  delete(filename);

end

function value = model_file(name)
  value = fullfile(get_test_data_dir(), '..', 'data', 'model', ['model-' name '_smdl.json']);
end
