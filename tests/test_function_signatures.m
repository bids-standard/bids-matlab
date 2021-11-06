function test_suite = test_function_signatures %#ok<*STOUT>
  % Copyright (C) 2020--, BIDS-MATLAB developers
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_function_signatures_basic()
  % Test functionSignatures.json file
  %
  % Copyright (C) 2020--, BIDS-MATLAB developers

  % only works with 2018b
  % validateFunctionSignaturesJSON

end
