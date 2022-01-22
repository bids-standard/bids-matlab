function test_suite = test_derivatives_json %#ok<*STOUT>

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_derivatives_json_basic()

  %% not a derivative file
  filename = 'sub-01_ses-test_task-faceRecognition_run-02_bold.nii';

  json = bids.derivatives_json(filename);

  expected.filename = '';
  expected.content = '';

  assertEqual(json, expected);

end

function test_derivatives_json_force()

  %% force to create default content
  filename = 'sub-01_task-faceRecognition_bold.nii';

  json = bids.derivatives_json(filename, 'force', true);

  expected.content = expected_content();
  expected.filename = 'sub-01_task-faceRecognition_bold.json';

  assertEqual(json, expected);

end

function test_derivatives_json_preproc()

  filename = 'sub-01_task-faceRecognition_res-hi_den-lo_desc-preproc_bold.nii.gz';

  json = bids.derivatives_json(filename);

  content = expected_content();

  content.Resolution = {{ struct('hi', 'REQUIRED if "res" entity') }};
  content.Density = {{ struct('lo', 'REQUIRED if "den" entity') }};

  expected.content = content;
  expected.filename = 'sub-01_task-faceRecognition_res-hi_den-lo_desc-preproc_bold.json';

  assertEqual(json.filename, expected.filename);
  assertEqual(json.content, expected.content);

end

function test_derivatives_json_segmentation()

  filename = 'sub-01_desc-T1w_dseg.nii.gz';

  json = bids.derivatives_json(filename);

  content = expected_content();
  content.Manual = {{'OPTIONAL'}};
  content.Atlas = {{'OPTIONAL'}};

  expected.content = content;
  expected.filename = 'sub-01_desc-T1w_dseg.json';

  assertEqual(json.filename, expected.filename);
  assertEqual(json.content, expected.content);

end

function test_derivatives_json_mask()

  filename = 'sub-01_mask.nii.gz';

  json = bids.derivatives_json(filename);

  content = expected_content();
  content.RawSources = {{'REQUIRED'}};
  content.Atlas = {{'OPTIONAL'}};
  content.Type = {{'OPTIONAL'}};

  expected.content = content;
  expected.filename = 'sub-01_mask.json';

  assertEqual(json.filename, expected.filename);
  assertEqual(json.content, expected.content);

end

function content = expected_content()

  content = struct('Description', 'RECOMMENDED');
  content.Sources = {{'OPTIONAL'}};
  content.RawSources = {{'OPTIONAL'}};
  content.SpatialReference = {{ ['REQUIRED if no space entity ', ...
                                 'or if non standard space RECOMMENDED otherwise'] }};

end
