function test_suite = test_report %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_report_basic()

  Subj = 1;
  Ses = 1;
  Run = 1;
  ReadNII = true;
  verbose = false;

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds001'));

  bids.report(BIDS, Subj, Ses, Run, ReadNII, verbose);

end
