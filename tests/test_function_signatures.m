function test_suite = test_function_signatures %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_function_signatures_basic()
  % Test functionSignatures.json file
  % The functionSignatures file is used by Matlab to provide code suggestions
  % and completions for functions.
  %
  % __________________________________________________________________________
  %
  % BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
  %   The brain imaging data structure, a format for organizing and
  %   describing outputs of neuroimaging experiments.
  %   K. J. Gorgolewski et al, Scientific Data, 2016.
  % __________________________________________________________________________
  %
  % Copyright (C) 2020--, BIDS-MATLAB developers

  root_dir = fullfile(fileparts(mfilename('fullpath')), '..');

  % Run a smoke test - see if the file is a readable json
  signatures = bids.util.jsondecode( ...
                                    fullfile(root_dir, 'functionSignatures.json'));
  assert(isstruct(signatures));

end
