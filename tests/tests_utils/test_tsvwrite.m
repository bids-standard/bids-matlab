function test_suite = test_tsvwrite %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_datetime_in_table()
  % TODO fix line issue on windows
  if bids.internal.is_octave() || ispc()
    moxunit_throw_test_skipped_exception('no datetime in Octave and line issue in windows');
  end
  x = '201401010000';
  acq_time = datetime(x, 'InputFormat', 'yyyyMMddHHmm');
  sub_id = {'foo'};
  patients = table(sub_id, acq_time);
  file = fullfile(tempname(), 'foo.tsv');
  bids.util.mkdir(fileparts(file));
  bids.util.tsvwrite(file, patients);

  FID = fopen(file, 'r');
  C = textscan(FID, '%s%s', 'Delimiter', '\t', 'EndOfLine', '\n');
  assertEqual(C{2}{2}, '2014-01-01T00:00:00.000');
end

function test_nan_in_table()
  % TODO fix line issue on windows
  if bids.internal.is_octave()  || ispc()
    moxunit_throw_test_skipped_exception('no table in Octave and line issue in windows');
  end
  sub_id = {'foo'; 'bar'};
  age = [25; nan];
  patients = table(sub_id, age);
  file = fullfile(tempname(), 'foo.tsv');
  bids.util.mkdir(fileparts(file));
  bids.util.tsvwrite(file, patients);

  FID = fopen(file, 'r');
  C = textscan(FID, '%s%s', 'Delimiter', '\t', 'EndOfLine', '\n');
  assertEqual(C{2}{3}, 'n/a');
end

function test_tsvwrite_basic()

  pth = fileparts(mfilename('fullpath'));

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

  % read the file &
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
  assertEqual(C{5}{3}(1), '3');
  % this would fail on windows
  % assertEqual(C{5}{3}, '3');

  delete(tsv_file);

end

% TODO test tsvread on tsv file using cell input

function test_tsvwrite_array

  pth = fileparts(mfilename('fullpath'));

  tsv_file = fullfile(pth, 'sub-01_task-ARRAY_events.tsv');

  a = [ ...
       0.123456, -10
       NaN, 1];

  bids.util.tsvwrite(tsv_file, a);

  FID = fopen(tsv_file, 'r');
  C = textscan(FID, '%s%s', 'Delimiter', '\t', 'EndOfLine', '\n');
  assertEqual(C{1}{2}, 'n/a');

  delete(tsv_file);

end

function test_read_write

  % ensure that reading and then writing does not change the format

  pth = fileparts(mfilename('fullpath'));

  tsv_file = fullfile(pth, '..', 'data', 'sub-01_recording-autosampler_blood.tsv');
  output = bids.util.tsvread(tsv_file);

  new_tsv_file = fullfile(pth, '..', 'data', 'sub-01_recording-autosampler_blood_new.tsv');
  bids.util.tsvwrite(new_tsv_file, output);

  % reread the new file and makes sure their content match
  new_output = bids.util.tsvread(new_tsv_file);
  assertEqual(output, new_output);

end

%% TODO

% The following test is silenced until we decide to support a "row wise structure"
% as a possible data shape for the input opf TSV write

% function test_tsvwrite_row_wise_structure()
%
%   pth = fileparts(mfilename('fullpath'));
%
%   tsv_file = fullfile(pth, 'sub-01_task-STRUCTURE_events.tsv');
%
%   logFile(1, 1).onset = 2;
%   logFile(1, 1).trial_type = 'motion_up';
%   logFile(1, 1).duration = 1;
%   logFile(1, 1).speed = [];
%   logFile(1, 1).is_fixation = true;
%
%   logFile(2, 1).onset = NaN;
%   logFile(2, 1).trial_type = 'static';
%   logFile(2, 1).duration = 4;
%   logFile(2, 1).speed = 4;
%   logFile(2, 1).is_fixation = 3;
%
%   bids.util.tsvwrite(tsv_file, logFile);
%
%   % read the file &
%   % check the extra columns of the header and some of the content
%
%   FID = fopen(tsv_file, 'r');
%   C = textscan(FID, '%s%s%s%s%s', 'Delimiter', '\t', 'EndOfLine', '\n');
%
%   % check header
%   assertEqual(C{4}{1}, 'speed');
%
%   % check that empty values are entered as NaN: logFile.speed(1)
%   assertEqual(C{4}{2}, 'n/a');
%
%   % check that missing fields are entered as NaN: logFile.speed(2)
%   assertEqual(C{4}{3}, '4');
%
%   % check that NaN are written as : logFile.onset(2)
%   assertEqual(C{1}{3}, 'n/a'); %
%
%   % check values entered properly: logFile.is_fixation(2)
%   assertEqual(C{5}{3}, '3');
%
% end
