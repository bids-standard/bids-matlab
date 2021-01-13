function test_suite = test_tsvwrite %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_tsvwrite_basic()
  % Test the tsvread function
  % __________________________________________________________________________
  %
  % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
  %   The brain imaging data structure, a format for organizing and
  %   describing outputs of neuroimaging experiments.
  %   K. J. Gorgolewski et al, Scientific Data, 2016.
  % __________________________________________________________________________
  %
  % Copyright (C) 2020, Remi Gau
  % Copyright (C) 2020--, BIDS-MATLAB developers
  %
  %
  % Small test to ensure that the functionality of the tsvwrite function
  pth = fileparts(mfilename('fullpath'));

  %% test tsvread on tsv file using structure input

  % ---- set up

  tsv_file = fullfile(pth, 'sub-01_task-STRUCTURE_events.tsv');

  logFile(1, 1).onset = 2;
  logFile(1, 1).trial_type = 'motion_up';
  logFile(1, 1).duration = 1;
  logFile(1, 1).speed = [];
  logFile(1, 1).is_fixation = true;

  logFile(2, 1).onset = NaN;
  logFile(2, 1).trial_type = 'static';
  logFile(2, 1).duration = 4;
  logFile(2, 1).is_fixation = 3;

  bids.util.tsvwrite(tsv_file, logFile);

  % ---- test section

  % read the file
  % check the extra columns of the header and some of the content

  FID = fopen(tsv_file, 'r');
  C = textscan(FID, '%s%s%s%s%s', 'Delimiter', '\t', 'EndOfLine', '\n');

  % check header
  assert(isequal(C{4}{1}, 'speed'));

  % check that empty values are entered as NaN: logFile(1,1).speed
  assert(isequal(C{4}{2}, 'n/a'));

  % check that missing fields are entered as NaN: logFile(2,1).speed
  assert(isequal(C{4}{3}, 'n/a'));

  % check that NaN are written as : logFile(2,1).onset
  assert(isequal(C{1}{3}, 'n/a')); %

  % check values entered properly: logFile(2,1).is_fixation
  assert(isequal(str2double(C{5}{3}), 3));

  %% test tsvread on tsv file using cell input
  % TO DO?

  %% test tsvread on tsv file using array input
  tsv_file = fullfile(pth, 'sub-01_task-ARRAY_events.tsv');

  a = [ ...
       0.123456, -10
       NaN, 1];

  bids.util.tsvwrite(tsv_file, a);

  FID = fopen(tsv_file, 'r');
  C = textscan(FID, '%s%s', 'Delimiter', '\t', 'EndOfLine', '\n');
  assert(isequal(C{1}{2}, 'n/a')); %

end
