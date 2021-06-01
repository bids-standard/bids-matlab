function test_suite = test_copy_to_derivative %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

%% TODO
%
% - add test to unzip

function test_copy_to_derivative_basic()

  [BIDS, out_path, filters, cfg] = fixture('qmri_tb1tfl');

  pipeline_name = 'bids-matlab';
  unzip = false;
  verbose = cfg.verbose;

  bids.copy_to_derivative(BIDS, out_path, pipeline_name, ...
                          filters, ...
                          'unzip', unzip, ...
                          'verbose', verbose);

  % force copy
  force = true;
  skip_dependencies = false;
  use_schema = false;
  verbose = cfg.verbose;

  bids.copy_to_derivative(BIDS, ...
                          out_path, ...
                          pipeline_name, ...
                          filters, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  teardown(out_path);

end

function test_copy_to_derivative_dependencies()

  [BIDS, out_path, filters, cfg] = fixture('qmri_mp2rageme');

  pipeline_name = 'bids-matlab';
  unzip = false;
  force = false;
  use_schema = true;
  verbose = cfg.verbose;

  skip_dependencies = true;

  bids.copy_to_derivative(BIDS, ...
                          out_path, ...
                          pipeline_name, ...
                          filters, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), false(), verbose);
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 20);

  teardown(out_path);
  bids.util.mkdir(out_path);

  %%
  skip_dependencies = false;

  bids.copy_to_derivative(BIDS, ...
                          out_path, ...
                          pipeline_name, ...
                          filters, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), false(), verbose);
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 22);

  teardown(out_path);

end

function test_copy_to_derivative_sessions_scans_tsv

  [BIDS, out_path, filters, cfg] = fixture('7t_trt');

  pipeline_name = 'bids-matlab';
  unzip = false;
  force = false;
  use_schema = true;
  verbose = cfg.verbose;
  skip_dependencies = true;

  bids.copy_to_derivative(BIDS, ...
                          out_path, ...
                          pipeline_name, ...
                          filters, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, pipeline_name), false(), verbose);
  assert(~isempty(derivatives.subjects(1).scans));
  assertEqual(derivatives.subjects(1).sess, derivatives.subjects(2).sess);

  teardown(out_path);

end

function [BIDS, out_path, filters, cfg] = fixture(dataset)

  cfg = set_test_cfg();

  pth_bids_example = get_test_data_dir();
  BIDS = fullfile(pth_bids_example, dataset);

  % to test on real data uncomment the following line
  % see tests/README.md to see how to install the data
  %
  %   input_dir = fullfile('..', 'data', 'ds000117');

  out_path = fullfile(pwd, 'data', dataset, 'derivatives');

  if exist(out_path, 'dir')
    rmdir(out_path, 's');
  end

  bids.util.mkdir(out_path);

  filters = struct();

  switch dataset

    case 'qmri_mp2rageme'
      filters = struct('suffix', 'MP2RAGE');

    case 'asl004'
      filters = struct('sub', 'Sub1', ...
                       'modality', 'perf');
      filters.suffix =  {'asl', 'm0scan'};

    case 'ds000117'
      filters = struct('sub', '01', ...
                       'modality', 'func', ...
                       'suffix', 'bold');
      filters.run = {'01'; '03'};

    case '7t_trt'
      filters.sub = {'01'; '02'; '03'; '04'};

    case 'MoAEpilot'

  end

end

function teardown(out_path)
  rmdir(out_path, 's');
end
