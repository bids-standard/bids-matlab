function test_suite = test_report %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_report_basic()

  cfg = set_up();

  filter.sub = '01';

  datasets = {'ds000117'};
  modalities = {'func', 'anat', 'dwi', 'fmap', 'meg'};

  for i = 1:numel(datasets)

    BIDS = fullfile(cfg.pth_bids_example, datasets{i});
    BIDS = bids.layout(BIDS, true);

    for j = 1:numel(modalities)

      filter.modality =  modalities{j};

      report = bids.report(BIDS, ...
                           'filter', filter, ...
                           'output_path', cfg.output_path, ...
                           'read_nifti', cfg.read_nifti, ...
                           'verbose', cfg.verbose);

      % content = get_report_content(report);
      % expected = get_expected_content(cfg, datasets{i}, modalities{j})
      % assertEqual(content, expected);

    end
  end

end

function test_report_asl()

  cfg = set_up();

  BIDS = fullfile(cfg.pth_bids_example, 'asl003');

  BIDS = bids.layout(BIDS, true);

  filter.modality = 'perf';

  report = bids.report(BIDS, ...
                       'filter', filter, ...
                       'output_path', cfg.output_path, ...
                       'verbose', cfg.verbose);

  %     content = get_report_content(report);

  %     expected = fullfile(cfg.this_path, 'data', ...
  % 'reports', ...
  % [datasets{i} '_' modalities{j} '.md']);
  %     expected = get_report_content(expected);

  %     assertEqual(content, expected);

end

function test_report_pet()

  cfg = set_up();

  BIDS = fullfile(cfg.pth_bids_example, 'pet001');

  BIDS = bids.layout(BIDS, true);

  filter.modality = 'pet';

  report = bids.report(BIDS, ...
                       'filter', filter, ...
                       'output_path', cfg.output_path, ...
                       'verbose', cfg.verbose);

  %     content = get_report_content(report);

  %     expected = fullfile(cfg.this_path, 'data', ...
  % 'reports', ...
  % [datasets{i} '_' modalities{j} '.md']);
  %     expected = get_report_content(expected);

  %     assertEqual(content, expected);

end

function test_report_moae_data()

  cfg = set_up();

  cfg.read_nifti = true;

  BIDS = fullfile(bids.internal.root_dir(), 'examples', 'MoAEpilot');

  BIDS = bids.layout(BIDS, true);

  report = bids.report(BIDS, ...
                       'output_path', cfg.output_path, ...
                       'read_nifti', cfg.read_nifti, ...
                       'verbose', cfg.verbose);

  %     content = get_report_content(report);

  %     expected = fullfile(cfg.this_path, 'data', ...
  % 'reports', ...
  % [datasets{i} '_' modalities{j} '.md']);
  %     expected = get_report_content(expected);

  %     assertEqual(content, expected);

end

function expected = get_expected_content(cfg, dataset, modality)
  expected = fullfile(cfg.this_path, 'data', ...
                      'reports', ...
                      [dataset '_' modality '.md']);
  expected = get_report_content(expected);
end

function cfg = set_up()

  cfg = set_test_cfg();

  cfg.this_path = fileparts(mfilename('fullpath'));
  cfg.output_path = fullfile(cfg.this_path, 'output');

  cfg.read_nifti = false;

  cfg.pth_bids_example = get_test_data_dir();

end

function content = get_report_content(file)
  fid = fopen(file);
  content = fscanf(fid, '%s');
  fclose(fid);
end
