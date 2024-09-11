function test_suite = test_create_scans_tsv %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_scans_tsv_basic_no_session()

  source_ds = fullfile(get_test_data_dir(), 'asl001');
  tmp_path = temp_dir();
  copyfile(source_ds, tmp_path);
  if bids.internal.is_octave()
    bids_path = fullfile(tmp_path, 'asl001');
  else
    bids_path = tmp_path;
  end

  output_filenames = bids.util.create_scans_tsv(bids_path, 'verbose', false);

  assertEqual(numel(output_filenames), 1);
  assertEqual(exist(fullfile(bids_path, output_filenames{1}), 'file'), 2);
  content = bids.util.tsvread(fullfile(bids_path, output_filenames{1}));
  assertEqual(fieldnames(content), {'filename'; 'acq_time'; 'comments'});

end

function test_create_scans_tsv_basic()

  source_ds = fullfile(get_test_data_dir(), 'ds006');
  tmp_path = temp_dir();
  copyfile(source_ds, tmp_path);
  if bids.internal.is_octave()
    bids_path = fullfile(tmp_path, 'ds006');
  else
    bids_path = tmp_path;
  end

  output_filenames = bids.util.create_scans_tsv(bids_path, 'verbose', false);

  assertEqual(numel(output_filenames), 28);
  assertEqual(exist(fullfile(bids_path, output_filenames{1}), 'file'), 2);
  content = bids.util.tsvread(fullfile(bids_path, output_filenames{1}));
  assertEqual(fieldnames(content), {'filename'; 'acq_time'; 'comments'});

end
