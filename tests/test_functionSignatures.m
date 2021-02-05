function test_functionSignatures(pth)
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

  if ~nargin
    % parent directory of the tests directory
    pth = fullfile(pwd, '..');
  end

  % Run a smoke test - see if the file is a readable json
  signatures = bids.util.jsondecode( ...
                                    fullfile(pth, 'functionSignatures.json'));
  assert(isstruct(signatures));
