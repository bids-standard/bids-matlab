function test_suite = test_copy_to_derivative %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_copy_to_derivative_ds000001()

  input_dir = fullfile(pwd, 'data', 'ds000001');
  out_path = fullfile(pwd, 'data', 'derivatives');

  if exist(out_path, 'dir')
    rmdir(out_path, 's');
  end

  BIDS = fullfile(input_dir);

  what_to_copy = struct('sub', '01', ...
                        'modality', 'func', ...
                        'suffix', 'bold');
  what_to_copy.run = {'01'; '03'};

  pipeline_name = 'bids-matlab';

  derivatives = bids.copy_to_derivative(BIDS, out_path, pipeline_name, what_to_copy);

end

% function test_copy_to_derivative_MoAE()
%
%   input_dir = download_moae_ds(true());
%   out_path = fullfile(input_dir, 'MoAEpilot', 'derivatives');
%
%   BIDS = fullfile(input_dir, 'MoAEpilot');
%
%   pipeline_name = 'bids-matlab';
%
%   derivatives = bids.copy_to_derivative(BIDS, out_path, pipeline_name);
%
% end
