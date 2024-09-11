function test_suite = test_create_participants_tsv %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_participants_tsv_basic()

  bids_path = temp_dir();

  copyfile(fullfile(get_test_data_dir(), 'asl001'), bids_path);

  if bids.internal.is_octave
    bids_path = fullfile(bids_path, 'asl001');
  end

  output_filename = bids.util.create_participants_tsv(bids_path, 'verbose', false);

  participants = bids.util.tsvread(output_filename);
  assertEqual(participants.participant_id, {'sub-Sub103'});

  delete(output_filename);

end

function test_create_participants_tsv_already_exist()

  skip_if_octave('mixed-string-concat warning thrown');

  bids_path = temp_dir();
  copyfile(fullfile(get_test_data_dir(), 'ds210'), bids_path);
  if bids.internal.is_octave
    bids_path = fullfile(bids_path, 'ds210');
  end

  output_filename = bids.util.create_participants_tsv(bids_path);

  assertWarning(@()bids.util.create_participants_tsv(bids_path, 'verbose', true), ...
                'create_participants_tsv:participantFileExist');

end
