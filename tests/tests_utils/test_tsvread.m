function test_suite = test_tsvread %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_tsvread_gz()

  [pth, expected] = fixture();

  tsv_file = fullfile(pth, 'sub-01_task-auditory_events.tsv.gz');
  output = bids.util.tsvread(tsv_file);
  assertEqual(output, expected);

end

function test_tsvread_subset()

  [pth, expected] = fixture();

  tsv_file = fullfile(pth, 'sub-01_task-auditory_events.tsv');
  output = bids.util.tsvread(tsv_file, 'onset');
  assertEqual(output, expected.onset);
  assert(~isfield(output, 'duration'));

end

function test_tsvread_basic()

  [pth, expected] = fixture();

  tsv_file = fullfile(pth, 'sub-01_task-auditory_events.tsv');
  output = bids.util.tsvread(tsv_file);
  assertEqual(output, expected);

end

function test_tsvread_bug_552()

  tsv_file = fullfile(get_test_data_dir(), '..', 'data', 'bom_bug_552.tsv');
  content = bids.util.tsvread(tsv_file);
  assert(ismember('onset', fieldnames(content)));

end

function [pth, expected] = fixture()

  pth = fullfile(get_test_data_dir(), '..', 'data');

  expected.onset = ([42 126 210 294 378 462 546])';
  expected.duration = repmat(42, 7, 1);
  expected.trial_type = repmat({'listening'}, 7, 1);

end
