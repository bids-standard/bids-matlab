function test_suite = test_create_sessions_tsv %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_sessions_tsv_no_session()

  bids_path = fullfile(get_test_data_dir(), 'ds210');

  [sts, msg] = bids.validate(bids_path,  '--ignoreNiftiHeaders');
  assertEqual(sts, 0);

  output_filenames = bids.util.create_sessions_tsv(bids_path, 'verbose', false);

  assert(isempty(output_filenames));
  assertEqual(exist(output_filenames, 'file'), 0);

  [sts, msg] = bids.validate(bids_path,  '--ignoreNiftiHeaders');
  assertEqual(sts, 0);

  assertWarning(@() bids.util.create_sessions_tsv(bids_path, 'verbose', true), ...
                'create_sessions_tsv:noSessionInDataset');

end

function test_create_sessions_tsv_basic()

  bids_path = fullfile(get_test_data_dir(), 'ieeg_epilepsy');

  [sts, msg] = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders');
  assertEqual(sts, 0);

  output_filenames = bids.util.create_sessions_tsv(bids_path, 'verbose', false);

  assertEqual(numel(output_filenames), 1);
  assertEqual(exist(fullfile(bids_path, output_filenames{1}), 'file'), 2);
  content = bids.util.tsvread(fullfile(bids_path, output_filenames{1}));
  assertEqual(fieldnames(content), {'session_id'; 'acq_time'; 'comments'});
  assertEqual(content.session_id, {'ses-postimp'; 'ses-preimp'});

  [sts, msg] = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders');
  assertEqual(sts, 0);

  teardown(bids_path, output_filenames);

end

function teardown(pth, filelist)
  for i = 1:numel(filelist)
    delete(fullfile(pth, filelist{i}));
  end
end
