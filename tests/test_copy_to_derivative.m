function test_suite = test_copy_to_derivative %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_copy_to_derivative_basic()

  input_dir = download_moae_ds(true());
  out_path = fullfile(input_dir, 'MoAEpilot', 'derivatives');

  BIDS = fullfile(input_dir, 'MoAEpilot');

  pipeline_name = 'bids-matlab';

  derivatives = bids.copy_to_derivative(BIDS, out_path, pipeline_name);

end

%
% function test_copy_to_derivative_fmriprep()
%
%
%
% end
