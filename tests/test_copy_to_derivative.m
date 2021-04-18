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

function test_copy_to_derivative_ds000117()

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

  %%
  pipeline_name = [];
  unzip = false;
  force = false;
  skip_dependencies = false;
  use_schema = false;
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

  derivatives = bids.layout(out_path);
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 13);

  %% same but we skip dependencies
  if exist(out_path, 'dir')
    rmdir(out_path, 's');
  end
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

  derivatives = bids.layout(out_path);                                    
  copied_files = bids.query(derivatives, 'data');
  assertEqual(size(copied_files, 1), 4);

  %% add test to check that only files that conform to schema are copied

end
