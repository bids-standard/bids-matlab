function test_suite = test_layout %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_layout_filter()

  verbose = false;

  BIDS = bids.layout(fullfile(get_test_data_dir(), '7t_trt'), ...
                     'verbose', verbose, ...
                     'filter', struct('sub', {{'^.*0[12]'}}, ...
                                      'modality', {{'anat', 'func'}}, ...
                                      'ses', {{'[1]'}}));

  subjects = bids.query(BIDS, 'subjects');
  assertEqual(subjects, {'01', '02'});

  subjects = bids.query(BIDS, 'modalities');
  assertEqual(subjects, {'anat', 'func'});

  subjects = bids.query(BIDS, 'sessions');
  assertEqual(subjects, {'1'});

end

function test_layout_empty_subject_folder_allowed_when_schemaless()

  verbose = false;

  bids.util.mkdir(fullfile(pwd, 'tmp/sub-01'));
  bids.layout(fullfile(pwd, 'tmp'), 'use_schema', false, 'verbose', verbose);
  rmdir(fullfile(pwd, 'tmp'), 's');
end

function test_layout_smoke_test()

  verbose = false;

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'genetics_ukbb'), 'verbose', verbose);

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds210'), 'verbose', verbose);

end
