function test_suite = test_create_scans_tsv %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_scans_tsv_basic()

  bids_path = fullfile(get_test_data_dir(), 'ieeg_epilepsy');

  output_filenames = bids.util.create_scans_tsv(bids_path, 'verbose', false);

  assertEqual(numel(output_filenames), 1);
  assertEqual(exist(output_filenames{1}, 'file'), 2);
  content = bids.util.tsvread(output_filenames{1});
  assertEqual(fieldnames(content), {'filename'; 'acq_time'; 'comments'});

  teardown(output_filenames);

end

function teardown(filelist)
  for i = 1:numel(filelist)
    delete(filelist{i});
  end
end
