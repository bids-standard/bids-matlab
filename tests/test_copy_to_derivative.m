function test_suite = test_copy_to_derivative %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_copy_to_derivative_unzip_force_false_572
  % unzip should not occur if output file already exist and force is false

  [pth, out_path, filter, cfg] = fixture('MoAEpilot');

  pipeline_name = 'bids-matlab';
  unzip = true;
  force = false;
  use_schema = true;
  verbose = cfg.verbose;
  skip_dependencies = true;

  bids.copy_to_derivative(pth, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), ...
                            'use_schema', false, 'verbose', verbose);

  t1w = bids.query(derivatives, 'data', 'modality', 'anat');
  folder = fileparts(t1w{1});
  files = dir(fullfile(folder, '*.nii'));
  timestamp = files.date;

  pause(1);

  bids.copy_to_derivative(pth, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  t1w = bids.query(derivatives, 'data', 'modality', 'anat');
  folder = fileparts(t1w{1});
  files = dir(fullfile(folder, '*.nii'));
  assertEqual(files.date, timestamp);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), ...
                            'use_schema', false, 'verbose', verbose);

  zipped_files = bids.query(derivatives, 'data', 'extension', '.nii.gz');
  assertEqual(numel(zipped_files), 0);

end

function test_copy_to_derivative_unzip_force_false

  [pth, out_path, filter, cfg] = fixture('MoAEpilot');

  pipeline_name = 'bids-matlab';
  unzip = true;
  force = false;
  use_schema = true;
  verbose = cfg.verbose;
  skip_dependencies = true;

  bids.copy_to_derivative(pth, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), ...
                            'use_schema', false, 'verbose', verbose);

  zipped_files = bids.query(derivatives, 'data', 'extension', '.nii.gz');
  assertEqual(numel(zipped_files), 0);

end

function test_copy_to_derivative_exclude_with_regex()

  [BIDS, out_path, filter, cfg] = fixture('ds002');

  pipeline_name = 'bids-matlab';
  unzip = false;
  verbose = cfg.verbose;

  filter.sub = '0[1-9]'; % only include subjects with label that start with 0
  filter.task = '(?!mixed).*'; % exclude tasks that start with mixed

  bids.copy_to_derivative(BIDS, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'unzip', unzip, ...
                          'verbose', verbose);

  BIDSder = bids.layout(fullfile(out_path, pipeline_name));
  subjects = bids.query(BIDSder, 'subjects');
  assertEqual(numel(subjects), 9);
  tasks = bids.query(BIDSder, 'tasks');
  assertEqual(numel(tasks), 2);

  % test that no empty json are created
  no_file_expected = bids.internal.file_utils('FPList', ...
                                              fullfile(out_path, ...
                                                       'bids-matlab', ...
                                                       'sub-01', ...
                                                       'func'), ...
                                              '.*_events.json');
  assert(isempty(no_file_expected));

end

function test_copy_to_derivative_GeneratedBy()

  [BIDS, out_path, ~, cfg] = fixture('qmri_vfa');

  filter =  struct('modality', 'anat');

  pipeline_name = 'SPM12';

  bids.copy_to_derivative(BIDS, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'force', true, ...
                          'unzip', false, ...
                          'verbose', cfg.verbose);

  BIDS = bids.layout(fullfile(out_path, 'SPM12'));

  assertEqual(BIDS.description.GeneratedBy.Name, 'SPM12');

end

function test_copy_to_derivative_basic()

  [BIDS, out_path, filter, cfg] = fixture('qmri_tb1tfl');

  pipeline_name = 'bids-matlab';
  unzip = false;
  verbose = cfg.verbose;

  bids.copy_to_derivative(BIDS, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'unzip', unzip, ...
                          'verbose', verbose);

  BIDSder = bids.layout(fullfile(out_path, pipeline_name));
  assertEqual(BIDSder.description.GeneratedBy.Name, 'bids-matlab');

  % force copy
  force = true;
  skip_dependencies = false;
  use_schema = false;
  verbose = cfg.verbose;

  bids.copy_to_derivative(BIDS, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

end

function test_copy_to_derivative_unzip

  [pth, out_path, filter, cfg] = fixture('MoAEpilot');

  pipeline_name = 'bids-matlab';
  unzip = true;
  force = false;
  use_schema = true;
  verbose = cfg.verbose;
  skip_dependencies = true;

  bids.copy_to_derivative(pth, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), ...
                            'use_schema', false, 'verbose', verbose);

  zipped_files = bids.query(derivatives, 'data', 'extension', '.nii.gz');
  assertEqual(numel(zipped_files), 0);

end

function test_copy_to_derivative_dependencies()

  [BIDS, out_path, filter, cfg] = fixture('qmri_mp2rageme');

  pipeline_name = 'bids-matlab';
  unzip = false;
  force = false;
  use_schema = true;
  verbose = cfg.verbose;

  skip_dependencies = true;

  bids.copy_to_derivative(BIDS, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), ...
                            'use_schema', false, ...
                            'verbose', verbose);
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 10);

  %%
  [BIDS, out_path, filter] = fixture('qmri_mp2rageme');

  skip_dependencies = false;

  bids.copy_to_derivative(BIDS, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), ...
                            'use_schema', false, ...
                            'verbose', verbose);
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 11);

end

function test_copy_to_derivative_sessions_scans_tsv

  [BIDS, out_path, filter, cfg] = fixture('7t_trt');

  pipeline_name = 'bids-matlab';
  unzip = false;
  force = false;
  use_schema = true;
  verbose = cfg.verbose;
  skip_dependencies = true;

  bids.copy_to_derivative(BIDS, ...
                          'pipeline_name', pipeline_name, ...
                          'out_path', out_path, ...
                          'filter', filter, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), ...
                            'use_schema', false, ...
                            'verbose', verbose);
  assert(~isempty(derivatives.subjects(1).scans));
  assertEqual(derivatives.subjects(1).sess, derivatives.subjects(2).sess);

end

function [BIDS, out_path, filter, cfg] = fixture(dataset)

  cfg = set_test_cfg();

  pth_bids_example = get_test_data_dir();
  BIDS = fullfile(pth_bids_example, dataset);

  % to test on real data uncomment the following line
  % see tests/README.md to see how to install the data
  %
  %   input_dir = fullfile('..', 'data', 'ds000117');

  out_path = fullfile(temp_dir, 'data', dataset, 'derivatives');

  bids.util.mkdir(out_path);

  filter = struct();

  switch dataset

    case 'qmri_mp2rageme'
      filter = struct('suffix', 'MP2RAGE');

    case 'asl004'
      filter = struct('sub', 'Sub1', ...
                      'modality', 'perf');
      filter.suffix =  {'asl', 'm0scan'};

    case 'ds000117'
      filter = struct('sub', '01', ...
                      'modality', 'func', ...
                      'suffix', 'bold');
      filter.run = {'01'; '03'};

    case '7t_trt'
      filter.sub = {'01'; '02'; '03'; '04'};

    case 'MoAEpilot'

      BIDS = moae_dir();

      if ~isdir(fullfile(BIDS, 'sub-01'))

        bids.util.download_ds('source', 'spm', ...
                              'demo', 'moae', ...
                              'force', true, ...
                              'verbose', false, ...
                              'delete_previous', true);
      end

      anat = fullfile(BIDS, 'sub-01', 'anat', 'sub-01_T1w.nii');
      if exist(anat, 'file')
        gzip(anat);
        delete(anat);
      end

      func = fullfile(BIDS, 'sub-01', 'func', 'sub-01_task-auditory_bold.nii');
      if exist(func, 'file')
        gzip(func);
        delete(func);
      end

    otherwise

  end

end
