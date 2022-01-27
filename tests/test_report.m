function test_suite = test_report %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_report_asl()

  cfg = set_up();

  datasets = 'asl003';

  BIDS = fullfile(cfg.pth_bids_example, datasets);

  BIDS = bids.layout(BIDS, 'use_schema', true);

  filter.modality = 'perf';

  report = bids.report(BIDS, ...
                       'filter', filter, ...
                       'output_path', cfg.output_path, ...
                       'verbose', cfg.verbose);

  content = get_report_content(report);
  expected = get_expected_content(cfg, datasets, filter.modality);

  % TODO make it work on Octave
  if bids.internal.is_octave()
    return
  end
  assertEqual(content, expected);

end

function test_report_basic()

  cfg = set_up();

  filter.sub = '01';

  datasets = {'ds000117'};
  modalities = {'func', 'anat', 'dwi', 'fmap', 'meg'};

  for i = 1:numel(datasets)

    BIDS = fullfile(cfg.pth_bids_example, datasets{i});
    BIDS = bids.layout(BIDS, 'use_schema', true);

    for j = 1:numel(modalities)

      filter.modality =  modalities{j};

      report = bids.report(BIDS, ...
                           'filter', filter, ...
                           'output_path', cfg.output_path, ...
                           'read_nifti', cfg.read_nifti, ...
                           'verbose', cfg.verbose);

      content = get_report_content(report);
      expected = get_expected_content(cfg, datasets{i}, modalities{j});

      % TODO make it work on Octave
      if bids.internal.is_octave()
        return
      end

      assertEqual(content, expected);

    end
  end

end

function test_report_pet()

  cfg = set_up();

  datasets = 'pet001';

  BIDS = fullfile(cfg.pth_bids_example, datasets);

  BIDS = bids.layout(BIDS, 'use_schema', true);

  filter.modality = 'pet';

  report = bids.report(BIDS, ...
                       'filter', filter, ...
                       'output_path', cfg.output_path, ...
                       'verbose', cfg.verbose);

  content = get_report_content(report);
  expected = get_expected_content(cfg, datasets, filter.modality);

  % TODO make it work on Octave
  if bids.internal.is_octave()
    return
  end
  assertEqual(content, expected);

end

function test_report_moae_data()

  % temporary silence
  return

  cfg = set_up();

  cfg.read_nifti = true;

  BIDS = fullfile(bids.internal.root_dir(), 'examples', 'MoAEpilot');

  BIDS = bids.layout(BIDS, 'use_schema', true);

  report = bids.report(BIDS, ...
                       'output_path', cfg.output_path, ...
                       'read_nifti', cfg.read_nifti, ...
                       'verbose', cfg.verbose);

  content = get_report_content(report);
  expected = get_expected_content(cfg, 'MoAE', 'all');

  % TODO make it work on Octave
  if bids.internal.is_octave()
    return
  end
  assertEqual(content, expected);

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
