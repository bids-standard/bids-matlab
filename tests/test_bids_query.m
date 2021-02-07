function test_suite = test_bids_query %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_basic()
  % Test BIDS queries
  % This dataset comes from https://github.com/bids-standard/bids-examples
  % and is downloaded automatically by the continuous integration framework
  % and is required for the tests to be run.
  % Based on https://en.wikibooks.org/wiki/SPM/BIDS#BIDS_parser_and_queries
  % __________________________________________________________________________
  %
  % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
  %   The brain imaging data structure, a format for organizing and
  %   describing outputs of neuroimaging experiments.
  %   K. J. Gorgolewski et al, Scientific Data, 2016.
  % __________________________________________________________________________

  % Copyright (C) 2019, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2019--, BIDS-MATLAB developers

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  subjs = arrayfun(@(x) sprintf('%02d', x), 1:20, 'UniformOutput', false);
  assert(isequal(bids.query(BIDS, 'subjects'), subjs));

  assert(isequal(bids.query(BIDS, 'runs'), {'01', '02'}));

  tasks = { ...
           'stopsignalwithletternaming', ...
           'stopsignalwithmanualresponse', ...
           'stopsignalwithpseudowordnaming'};
  assert(isequal(bids.query(BIDS, 'tasks'), tasks));

  suffixes = {'T1w', 'bold', 'events', 'inplaneT2'};
  assert(isequal(bids.query(BIDS, 'suffixes'), suffixes));

  data = bids.query(BIDS, 'data', 'sub', '01', 'task', 'stopsignalwithpseudowordnaming');
  assertEqual(size(data, 1), 4);

  assert(isempty(bids.query(BIDS, 'runs', 'suffix', 'T1w')));

  runs = {'01', '02'};
  assert(isequal(bids.query(BIDS, 'runs', 'suffix', 'bold'), runs));

  bold = bids.query(BIDS, 'data', ...
                    'sub', '05', ...
                    'run', '02', ...
                    'task', 'stopsignalwithmanualresponse', ...
                    'suffix', 'bold');
  assert(iscellstr(bold));
  assert(numel(bold) == 1);

  md = bids.query(BIDS, 'metadata', ...
                  'sub', '05', ...
                  'run', '02', ...
                  'task', 'stopsignalwithmanualresponse', ...
                  'suffix', 'bold');
  assert(isstruct(md) & isfield(md, 'RepetitionTime') & isfield(md, 'TaskName'));
  assert(md.RepetitionTime == 2);
  assert(strcmp(md.TaskName, 'stop signal with manual response'));

  t1 = bids.query(BIDS, 'data', 'suffix', 'T1w');
  assert(iscellstr(t1));
  assert(numel(t1) == numel(bids.query(BIDS, 'subjects')));

end

function test_bids_query_sessions()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'synthetic'));
  sessions = {'01', '02'};
  assert(isequal(bids.query(BIDS, 'sessions'), sessions));
  assert(isequal(bids.query(BIDS, 'sessions', 'sub', '02'), sessions));

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  assert(isempty(bids.query(BIDS, 'sessions')));

end

function test_bids_query_modalities()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds007'));

  modalities = {'anat', 'func'};
  assert(isequal(bids.query(BIDS, 'modalities'), modalities));
  assert(isequal(bids.query(BIDS, 'modalities', 'sub', '01'), modalities));

  BIDS = bids.layout(fullfile(pth_bids_example, '7t_trt'));

  modalities = {'anat', 'fmap', 'func'};

  assert(isequal(bids.query(BIDS, 'modalities'), modalities));
  assert(isequal(bids.query(BIDS, 'modalities', 'sub', '01'), modalities));
  assert(isequal(bids.query(BIDS, 'modalities', 'sub', '01', 'ses', '1'), modalities));

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

  % assert(isequal(bids.query(BIDS, 'modalities', 'sub', '01', 'ses', '2'), mods(2:3)));

end
