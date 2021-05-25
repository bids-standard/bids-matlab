function test_suite = test_report %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_report_basic()

  ReadNII = false;
  output_path = ''; % fullfile(fileparts(mfilename('fullpath')), 'output');
  verbose = true;

  sub = '';
  ses = '';

  pth_bids_example = get_test_data_dir();

  BIDS = fullfile(pth_bids_example, 'synthetic'); % ds001

  bids.report(BIDS, sub, ses, ReadNII, output_path, verbose);

end
