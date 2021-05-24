function test_suite = test_create_path %#ok<*STOUT>

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_create_path_basic()

  filename = 'sub-01_ses-test_bold.nii';
  path = bids.create_path(filename);
  assertEqual(path, fullfile('sub-01', 'ses-test', 'func'));

  % several modality possiblities for events
  filename = 'sub-01_ses-test_task-test_events.tsv';
  path = bids.create_path(filename);
  assertEqual(path, fullfile('sub-01', 'ses-test'));

  %   filename = 'participants.tsv';
  %   path = bids.create_path(filename);
  %   assertEqual(path, '');

end
