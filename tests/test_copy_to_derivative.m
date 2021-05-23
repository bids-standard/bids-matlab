function test_suite = test_copy_to_derivative %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_copy_to_derivative_sessions_scans_tsv

  [BIDS, out_path, filters] = fixture('7t_trt');

  pipeline_name = 'bids-matlab';
  unzip = false;
  force = false;
  use_schema = true;
  verbose = true;
  skip_dependencies = true;

  bids.copy_to_derivative(BIDS, ...
                          fullfile(out_path, '7t_trt'), ...
                          pipeline_name, ...
                          filters, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(fullfile(out_path, '7t_trt', pipeline_name), false());
  assert(~isempty(derivatives.subjects(1).scans));
  assertEqual(derivatives.subjects(1).sess, derivatives.subjects(2).sess);

end

function test_copy_to_derivative_MoAE()

  BIDS = download_moae_ds(true());
  out_path = fullfile(pwd, 'data', 'MoAEpilot', 'derivatives');

  pipeline_name = 'bids-matlab';

  bids.copy_to_derivative(BIDS, out_path, pipeline_name);

end
 
function test_copy_to_derivative_MoAE_force()

  BIDS = download_moae_ds(true());
  out_path = fullfile(pwd, 'data', 'MoAEpilot', 'derivatives');

  pipeline_name = 'bids-matlab';

  filters = struct();
  unzip = false;
  force = true;
  skip_dependencies = false;
  use_schema = true;
  verbose = true;

  bids.copy_to_derivative(BIDS, ...
                          out_path, ...
                          pipeline_name, ...
                          filters, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

end

function test_copy_to_derivative_ds000117()

  [BIDS, out_path, filters] = fixture('ds000117');

  pipeline_name = '';
  unzip = false;
  force = false;
  skip_dependencies = false;
  use_schema = true;
  verbose = true;

  bids.copy_to_derivative(BIDS, ...
                          out_path, ...
                          pipeline_name, ...
                          filters, ...
                          'use_schema', use_schema, ...
                          'unzip', unzip, ...
                          'force', force, ...
                          'skip_dep', skip_dependencies, ...
                          'verbose', verbose);

  derivatives = bids.layout(out_path, false());
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 10);

end

function test_copy_to_derivative_ds000117_skip_dependencies

  [BIDS, out_path, filters] = fixture('ds000117');

  pipeline_name = 'bids-matlab';
  unzip = false;
  force = false;
  use_schema = true;
  verbose = true;

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

  derivatives = bids.layout(fullfile(out_path, pipeline_name), false());
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 4);

end

function [BIDS, out_path, filters] = fixture(dataset)

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

  switch dataset

    case 'ds000117'

      filters = struct('sub', '01', ...
                       'modality', 'func', ...
                       'suffix', 'bold');
      filters.run = {'01'; '03'};

    case '7t_trt'

      filters.sub = {'01'; '02'; '03'; '04'};

    case 'MoAEpilot'

      filters = struct();

  end

end
