function test_suite = test_report_meg %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_report_all_param()

  read_nifti = false;
  output_path = fullfile(fileparts(mfilename('fullpath')), 'output');
  cfg = set_test_cfg();

  pth_bids_example = get_test_data_dir();

  filter.modality = 'meg';
  filter.sub = '01';

  datasets = {'ds000117'};

  for i = 1:numel(datasets)

    BIDS = fullfile(pth_bids_example, datasets{i});

    bids.report(BIDS, ...
                'filter', filter, ...
                'output_path', output_path, ...
                'read_nifti', read_nifti, ...
                'verbose', cfg.verbose);

  end
end
