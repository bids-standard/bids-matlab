function test_suite = test_copy_to_derivative %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_copy_to_derivative_MoAE()

  input_dir = download_moae_ds(true());
  out_path = fullfile(input_dir, 'MoAEpilot', 'derivatives');

  BIDS = fullfile(input_dir, 'MoAEpilot');

  pipeline_name = 'bids-matlab';

  derivatives = bids.copy_to_derivative(BIDS, out_path, pipeline_name);

end

function test_copy_to_derivative_ds000001()

  input_dir = fullfile('..', 'data', 'ds000001');
  out_path = fullfile('..', 'data', 'derivatives');

  if exist(out_path, 'dir')
    rmdir(out_path, 's');
  end

  BIDS = fullfile(input_dir);

  filters = struct('sub', '01', ...
                   'modality', 'func', ...
                   'suffix', 'bold');
  filters.run = {'01'; '03'};

  output_dir = [];
  pipeline_name = [];
  unzip = false;
  force = false;
  verbose = true;

  derivatives = bids.copy_to_derivative(BIDS, ...
                                        output_dir, ...
                                        pipeline_name, ...
                                        filters, ...
                                        unzip, ...
                                        force, ...
                                        verbose);

end
