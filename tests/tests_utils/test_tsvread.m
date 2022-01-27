function test_suite = test_tsvread %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_tsvread_basic()

  if ~bids.internal.is_octave() && bids.internal.is_github_ci()
    % TODO fix downloading of test data when testing with matlab in CI
    return
  else
    pth = bids.internal.download_moae_ds();
  end

  % define the expected output from bids query metadata
  events.onset = [42 126 210 294 378 462 546];

  %% test tsvread on tsv file
  tsv_file = fullfile(pth, 'sub-01', 'func', 'sub-01_task-auditory_events.tsv');
  output = bids.util.tsvread(tsv_file);
  assertEqual(output.onset', events.onset);

  %% test tsvread on zipped tsv file
  output = bids.util.tsvread(fullfile( ...
                                      fileparts(mfilename('fullpath')), '..', ...
                                      'data', ...
                                      'sub-01_task-auditory_events.tsv.gz'));
  assertEqual(output.onset', events.onset);

end

function test_tsvread_subset()

  if ~bids.internal.is_octave() && bids.internal.is_github_ci()
    % TODO fix downloading of test data when testing with matlab in CI
    return
  else
    pth = bids.internal.download_moae_ds();
  end

  % define the expected output from bids query metadata
  events.onset = [42 126 210 294 378 462 546];

  %% test tsvread on tsv file
  tsv_file = fullfile(pth, 'sub-01', 'func', 'sub-01_task-auditory_events.tsv');
  output = bids.util.tsvread(tsv_file, 'onset');
  assertEqual(output', events.onset);

end
