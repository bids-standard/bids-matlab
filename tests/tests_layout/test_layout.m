function test_suite = test_layout %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_layout_do_not_include_empty_subject()

  bids_dir = fullfile(get_test_data_dir(), 'qmri_tb1tfl');
  empty_sub = fullfile(bids_dir, 'sub-02');
  bids.util.mkdir(fullfile(bids_dir, 'sub-02'));

  verbose = false;
  BIDS = bids.layout(bids_dir, 'verbose', verbose);
  assertEqual(numel(bids.query(BIDS, 'subjects')), 1);
  assertEqual(numel(BIDS.subjects), 1);

  verbose = true;
  assertWarning(@()bids.layout(bids_dir, 'verbose', verbose), ...
                'layout:EmptySubject');

end

function test_layout_filter()

  verbose = false;

  BIDS = bids.layout(fullfile(get_test_data_dir(), '7t_trt'), ...
                     'verbose', verbose, ...
                     'filter', struct('sub', {{'01', '02'}}, ...
                                      'modality', {{'anat', 'func'}}, ...
                                      'ses', {{'1', '2'}}));

  subjects = bids.query(BIDS, 'subjects');
  assertEqual(subjects, {'01', '02'});

  subjects = bids.query(BIDS, 'modalities');
  assertEqual(subjects, {'anat', 'func'});

  subjects = bids.query(BIDS, 'sessions');
  assertEqual(subjects, {'1', '2'});

end

function test_layout_filter_regex()

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

function test_layout_smoke_test()

  verbose = false;

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'genetics_ukbb'), 'verbose', verbose);

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'ds210'), 'verbose', verbose);

end
