function test_suite = test_layout %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_warning_missing_participants_tsv()

  skip_if_octave('mixed-string-concat warning thrown');

  bids_dir = fullfile(get_test_data_dir(), 'qmri_tb1tfl');
  assertWarning(@()bids.layout(bids_dir, ...
                               'verbose', true), ...
                'layout:tsvMissing');

end

function test_no_warning_missing_participants_tsv_derivatives()

  skip_if_octave('mixed-string-concat warning thrown');

  bids_dir = fullfile(get_test_data_dir(), 'ds000001-fmriprep');
  try
    assertWarning(@()bids.layout(bids_dir, ...
                                 'verbose', true, ...
                                 'use_schema', false), ...
                  'layout:tsvMissing');
  catch ME
    assert(strcmp(ME.identifier, 'moxunit:warningNotRaised'));
  end

end

function test_layout_do_not_include_empty_subject()

  if ispc
    % TODO investigate
    moxunit_throw_test_skipped_exception('fail on windows');
  end

  bids_dir = fullfile(get_test_data_dir(), 'qmri_tb1tfl');
  empty_sub = fullfile(bids_dir, 'sub-02');
  bids.util.mkdir(fullfile(bids_dir, 'sub-02'));

  verbose = false;

  BIDS = bids.layout(bids_dir, 'verbose', verbose, 'use_schema', false);
  assertEqual(numel(bids.query(BIDS, 'subjects')), 1);
  assertEqual(numel(BIDS.subjects), 2);

  BIDS = bids.layout(bids_dir, 'verbose', verbose);
  assertEqual(numel(bids.query(BIDS, 'subjects')), 1);
  assertEqual(numel(BIDS.subjects), 1);

  rmdir(empty_sub);

end

function test_layout_do_not_include_empty_subject_warning()

  skip_if_octave('mixed-string-concat warning thrown');
  if ispc
    % TODO investigate
    moxunit_throw_test_skipped_exception('fail on windows');
  end

  bids_dir = fullfile(get_test_data_dir(), 'qmri_tb1tfl');
  empty_sub = fullfile(bids_dir, 'sub-02');
  bids.util.mkdir(fullfile(bids_dir, 'sub-02'));

  verbose = true;
  assertWarning(@()bids.layout(bids_dir, 'verbose', verbose), ...
                'layout:EmptySubject');

  rmdir(empty_sub);

end

function test_layout_error_message

  assertExceptionThrown(@()bids.layout('foo'), 'layout:InvalidInput');

end

function test_layout_filter()

  verbose = false;

  BIDS = bids.layout(fullfile(get_test_data_dir(), '7t_trt'), ...
                     'verbose', verbose, ...
                     'index_dependencies', false, ...
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
                     'index_dependencies', false, ...
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
