function test_suite = test_create_scans_tsv %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_scans_tsv_basic_no_session()

  bids_path = fullfile(get_test_data_dir(), 'asl001');

  [sts, msg] = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders'); %#ok<*ASGLU>
  assertEqual(sts, 0);

  output_filenames = bids.util.create_scans_tsv(bids_path, 'verbose', true);

  assertEqual(numel(output_filenames), 1);
  assertEqual(exist(fullfile(bids_path, output_filenames{1}), 'file'), 2);
  content = bids.util.tsvread(fullfile(bids_path, output_filenames{1}));
  assertEqual(fieldnames(content), {'filename'; 'acq_time'; 'comments'});

  [sts, msg] = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders');
  assertEqual(sts, 0);

  teardown(bids_path, output_filenames);

end

function test_create_scans_tsv_basic()

  bids_path = fullfile(get_test_data_dir(), 'ds000117');

  [sts, msg] = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders');
  assertEqual(sts, 0);

  output_filenames = bids.util.create_scans_tsv(bids_path, 'verbose', true);

  assertEqual(numel(output_filenames), 16);
  assertEqual(exist(output_filenames{1}, 'file'), 2);
  content = bids.util.tsvread(output_filenames{1});
  assertEqual(fieldnames(content), {'filename'; 'acq_time'; 'comments'});

  sts = bids.validate(bids_path,  '--config.ignore=99 --ignoreNiftiHeaders');
  assertEqual(sts, 0);

  teardown(bids_path, output_filenames);

end

function teardown(pth, filelist)
  for i = 1:numel(filelist)
    delete(fullfile(pth, filelist{i}));
  end
end
