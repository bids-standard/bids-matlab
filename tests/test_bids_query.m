function test_suite = test_bids_query %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

  % Copyright (C) 2019, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2019--, BIDS-MATLAB developers

end

function test_query_basic()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  tasks = { ...
           'stopsignalwithletternaming', ...
           'stopsignalwithmanualresponse', ...
           'stopsignalwithpseudowordnaming'};
  assertEqual(bids.query(BIDS, 'tasks'), tasks);

  assert(isempty(bids.query(BIDS, 'runs', 'suffix', 'T1w')));

  runs = {'01', '02'};
  assertEqual(bids.query(BIDS, 'runs'), runs);
  assertEqual(bids.query(BIDS, 'runs', 'suffix', 'bold'), runs);

  % make sure that query can work with filter
  filters = {'sub', {'01', '03'}; ...
             'task', {'stopsignalwithletternaming', ...
                      'stopsignalwithmanualresponse'}; ...
             'run', '02'; ...
             'suffix', 'bold'};

  files_cell_filter = bids.query(BIDS, 'data', filters);
  assertEqual(size(files_cell_filter, 1), 4);

  filters = struct('run', '02', ...
                   'suffix', 'bold');
  filters.sub = {'01', '03'};
  filters.task = {'stopsignalwithletternaming', ...
                  'stopsignalwithmanualresponse'};

  files_struct_filter = bids.query(BIDS, 'data', filters);
  assertEqual(size(files_struct_filter, 1), 4);

  assertEqual(files_cell_filter, files_struct_filter);

end

function test_query_extension()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  extensions = bids.query(BIDS, 'extensions');

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'task', 'stopsignalwithpseudowordnaming', ...
                    'extension', '.nii.gz', ...
                    'suffix', 'bold');
  assertEqual(size(data, 1), 2);

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'task', 'stopsignalwithpseudowordnaming', ...
                    'extension', '.tsv');
  assertEqual(size(data, 1), 2);

end

function test_query_data()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  t1 = bids.query(BIDS, 'data', 'suffix', 'T1w');
  assert(iscellstr(t1));
  assert(numel(t1) == numel(bids.query(BIDS, 'subjects')));

  data = bids.query(BIDS, 'data', 'sub', '01', 'task', 'stopsignalwithpseudowordnaming');
  assertEqual(size(data, 1), 4);

  bold = bids.query(BIDS, 'data', ...
                    'sub', '05', ...
                    'run', '02', ...
                    'task', 'stopsignalwithmanualresponse', ...
                    'suffix', 'bold');
  assert(iscellstr(bold));
  assert(numel(bold) == 1);

end

function test_query_metadata()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  md = bids.query(BIDS, 'metadata', ...
                  'sub', '05', ...
                  'run', '02', ...
                  'task', 'stopsignalwithmanualresponse', ...
                  'suffix', 'bold');
  assert(isstruct(md) & isfield(md, 'RepetitionTime') & isfield(md, 'TaskName'));
  assert(md.RepetitionTime == 2);
  assert(strcmp(md.TaskName, 'stop signal with manual response'));

end

function test_query_modalities()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  modalities = {'anat', 'func'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);
  assertEqual(bids.query(BIDS, 'modalities', 'sub', '01'), modalities);

  BIDS = bids.layout(fullfile(pth_bids_example, '7t_trt'));

  modalities = {'anat', 'fmap', 'func'};

  assertEqual(bids.query(BIDS, 'modalities'), modalities);
  assertEqual(bids.query(BIDS, 'modalities', 'sub', '01'), modalities);
  assertEqual(bids.query(BIDS, 'modalities', 'sub', '01', 'ses', '1'), modalities);

  % this now fails on octave 4.2.2 but not on Matlab
  %
  % bids.query(BIDS, 'modalities', 'sub', '01', 'ses', '2')
  %
  % ans =
  % {
  %   [1,1] = anat
  %   [1,2] = fmap
  %   [1,3] = func
  % }
  %
  % when it should return

  % assertEqual(bids.query(BIDS, 'modalities', 'sub', '01', 'ses', '2'), mods(2:3)));

end

function test_query_subjects()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  subjs = arrayfun(@(x) sprintf('%02d', x), 1:20, 'UniformOutput', false);
  assertEqual(bids.query(BIDS, 'subjects'), subjs);

end

function test_query_sessions()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'synthetic'));
  sessions = {'01', '02'};
  assertEqual(bids.query(BIDS, 'sessions'), sessions);
  assertEqual(bids.query(BIDS, 'sessions', 'sub', '02'), sessions);

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  assert(isempty(bids.query(BIDS, 'sessions')));

end

function test_query_suffixes()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  suffixes = {'T1w', 'bold', 'events', 'inplaneT2'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

end
