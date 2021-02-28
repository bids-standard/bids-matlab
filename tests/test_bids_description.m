function test_suite = test_bids_description %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

  % Copyright (C) 2019, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2019--, BIDS-MATLAB developers

end

function test_description()

  ds_desc = bids.dataset_description;
  ds_desc = ds_desc.generate();
  ds_desc.write();

  is_derivative = true;
  ds_desc = bids.dataset_description;
  ds_desc = ds_desc.generate(is_derivative);
  ds_desc.write();
  
end
