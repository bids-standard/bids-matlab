function test_suite = test_create_default_model %#ok<*STOUT>
  %
  % (C) Copyright 2020 CPP_SPM developers

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_default_model_basic()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds001'));

  [content, filename] = bids.model.create_default_model(BIDS, 'balloonanalogrisktask');
  bids.util.jsonencode(fullfile(pwd, filename), content);
  content = bids.util.jsondecode(fullfile(pwd, filename));

  % check it has the right content
  expectedContent = bids.util.jsondecode(fullfile(fileparts(mfilename('fullpath')), ...
                                                  'models', ...
                                                  'model-default_smdl.json'));

  assertEqual(content.Steps{1}, expectedContent.Steps{1});
  assertEqual(content.Steps{2}, expectedContent.Steps{2});
  assertEqual(content.Steps{3}, expectedContent.Steps{3});
  assertEqual(content, expectedContent);

end
