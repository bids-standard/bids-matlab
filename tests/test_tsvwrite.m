function test_suite = test_tsvwrite %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_tsvwrite_basic()
  % Test the tsvwrite function
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

  logFile.onset = [2; NaN];
  logFile.trial_type = {'motion_up'; 'static'};
  logFile.duration = [1; 4];
  logFile.speed = [NaN; 4];
  logFile.is_fixation = {'true'; '3'};

  % Leads to trouble
  %   logFile.is_fixation = {'true';3};
  %   logFile.is_fixation = {true;3};

  bids.util.tsvwrite(tsv_file, logFile);

  % ---- test section

  % read the file
  % check the extra columns of the header and some of the content

  FID = fopen(tsv_file, 'r');
  C = textscan(FID, '%s%s%s%s%s', 'Delimiter', '\t', 'EndOfLine', '\n');

  % check header
  assertEqual(C{4}{1}, 'speed');

  % check that empty values are entered as NaN: logFile.speed(1)
  assertEqual(C{4}{2}, 'n/a');

  % check that missing fields are entered as NaN: logFile.speed(2)
  assertEqual(C{4}{3}, '4');

  % check that NaN are written as : logFile.onset(2)
  assertEqual(C{1}{3}, 'n/a'); %

  % check values entered properly: logFile.is_fixation(2)
  assertEqual(C{5}{3}, '3');

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
  assertEqual(C{1}{2}, 'n/a'); %

end

function test_read_write

  % ensure that reading and then writing does not change the format

  pth = fileparts(mfilename('fullpath'));

  tsv_file = fullfile(pth, 'data', 'sub-01_recording-autosampler_blood.tsv');
  output = bids.util.tsvread(tsv_file);

  new_tsv_file = fullfile(pth, 'data', 'sub-01_recording-autosampler_blood_new.tsv');
  bids.util.tsvwrite(new_tsv_file, output);

  % reread the new file and makes sure their content match
  new_output = bids.util.tsvread(new_tsv_file);
  assertEqual(output, new_output);

end
