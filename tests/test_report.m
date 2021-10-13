function test_suite = test_report %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_report_basic()

  read_nifti = false;
  output_path = fullfile(fileparts(mfilename('fullpath')), 'output');
  verbose = false;

  sub = '';
  ses = '';

  pth_bids_example = get_test_data_dir();

  datasets = {'ds000117' 'ds001' 'asl001' 'synthetic'};

  for i = 1:numel(datasets)

    BIDS = fullfile(pth_bids_example, datasets{i});

    BIDS = bids.layout(BIDS);

    bids.report(BIDS, sub, ses, output_path, 'read_nifti', read_nifti, 'verbose', verbose);

  end
end
