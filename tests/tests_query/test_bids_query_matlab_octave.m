function test_suite = test_bids_query_matlab_octave %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

% Just to track any eventual behavior difference between matlab and octave
% https://github.com/bids-standard/bids-matlab/issues/113

function test_query_impossible_suffix_should_return_empty()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, '7t_trt'));

  subjects = bids.query(BIDS, 'subjects');
  assertEqual(size(subjects), [1, 22]);

  sessions = bids.query(BIDS, 'sessions', 'sub', '01');
  assertEqual(sessions, {'1', '2'});

  % The next 2 relate to
  % https://github.com/bids-standard/bids-matlab/issues/112
  %
  % Keeping it here to track an eventual regression
  modalities = bids.query(BIDS, 'modalities', 'sub', '01', 'ses', '1');
  assertEqual(modalities, {'anat', 'fmap', 'func'});

  modalities = bids.query(BIDS, 'modalities', 'sub', '01', 'ses', '2');
  assertEqual(modalities, {'fmap', 'func'});

  % ignore sessions
  modalities = bids.query(BIDS, 'modalities', 'sub', '01', 'ses', '');
  assertEqual(modalities, {});

  modalities = bids.query(BIDS, 'modalities', 'sub', '01', 'ses', []);
  assertEqual(modalities, {});

  % non existent sessions or wrongly formatted session label
  modalities = bids.query(BIDS, 'modalities', 'sub', '01', 'ses', '999');
  assertEqual(modalities, {});

  modalities = bids.query(BIDS, 'modalities', 'sub', '01', 'ses', 2);
  assertEqual(modalities, {});

  % TODO
  %   assertWarning(@()bids.query(BIDS, 'modalities', 'sub', 1), ...
  %     'query:subjectLabelAreStrings')

end
