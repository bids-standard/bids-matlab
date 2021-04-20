function test_suite = test_copy_to_derivative %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_copy_to_derivative_MoAE()

  input_dir = download_moae_ds(true());
  out_path = [];

  BIDS = fullfile(input_dir, 'MoAEpilot');

  pipeline_name = 'bids-matlab';

  bids.copy_to_derivative(BIDS, out_path, pipeline_name);

end

function test_copy_to_derivative_MoAE_force()

  input_dir = download_moae_ds(true());
  out_path = [];

  BIDS = fullfile(input_dir, 'MoAEpilot');

  pipeline_name = 'bids-matlab';

  filters = [];
  unzip = false;
  force = true;
  skip_dependencies = false;
  use_schema = true;
  verbose = true;

  bids.copy_to_derivative(BIDS, ...
                          out_path, ...
                          pipeline_name, ...
                          filters, ...
                          unzip, ...
                          force, ...
                          skip_dependencies, ...
                          verbose);

end

function test_copy_to_derivative_ds000117()

  [BIDS, out_path, filters] = fixture();

  pipeline_name = [];
  unzip = false;
  force = false;
  skip_dependencies = false;
  use_schema = true;
  verbose = true;

  bids.copy_to_derivative(BIDS, ...
                          out_path, ...
                          pipeline_name, ...
                          filters, ...
                          unzip, ...
                          force, ...
                          skip_dependencies, ...
                          use_schema, ...
                          verbose);

  derivatives = bids.layout(out_path, false());
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 10);

end

function test_copy_to_derivative_ds000117_skip_dependencies

  [BIDS, out_path, filters] = fixture();

  pipeline_name = [];
  unzip = false;
  force = false;
  use_schema = true;
  verbose = true;

  skip_dependencies = true;

  bids.copy_to_derivative(BIDS, ...
                          out_path, ...
                          pipeline_name, ...
                          filters, ...
                          unzip, ...
                          force, ...
                          skip_dependencies, ...
                          use_schema, ...
                          verbose);

  derivatives = bids.layout(out_path, false());
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 4);

end

function [BIDS, out_path, filters] = fixture()

  pth_bids_example = get_test_data_dir();
  input_dir = fullfile(pth_bids_example, 'ds000117');

  % to test on real data uncomment the following line
  % see tests/README.md to see how to install the data
  %
  %   input_dir = fullfile('..', 'data', 'ds000117');

  out_path = fullfile(pwd, 'data', 'derivatives');

  if exist(out_path, 'dir')
    rmdir(out_path, 's');
  end

  BIDS = fullfile(input_dir);

  filters = struct('sub', '01', ...
                   'modality', 'func', ...
                   'suffix', 'bold');
  filters.run = {'01'; '03'};

end
