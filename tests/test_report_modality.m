function test_suite = test_report_modality %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_report_func()

  this_path = fileparts(mfilename('fullpath'));

  read_nifti = false;
  output_path = fullfile(this_path, 'output');
  cfg = set_test_cfg();

  pth_bids_example = get_test_data_dir();

  filter.modality = 'func';
  filter.sub = '01';

  datasets = {'ds001'};

  % TODO test on data with nifti content
  for i = 1:numel(datasets)

    BIDS = fullfile(pth_bids_example, datasets{i});

    report = bids.report(BIDS, ...
                         'filter', filter, ...
                         'output_path', output_path, ...
                         'read_nifti', read_nifti, ...
                         'verbose', cfg.verbose);

    fid = fopen(report);
    content = fscanf(fid, '%s');
    fclose(fid);

    fid = fopen(fullfile(this_path, 'data', 'reports', ...
                         [datasets{i} '_func.md']));
    expected = fscanf(fid, '%s');
    fclose(fid);

    assertEqual(content, expected);

  end
end
