function test_suite = test_create_participants_tsv %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_participants_tsv_basic()

  bids_path = fullfile(get_test_data_dir(), 'ds210');

  output_filename = bids.util.create_participants_tsv(bids_path);

  if ~bids.internal.is_octave()
    assertWarning(@()bids.util.create_participants_tsv(bids_path), ...
                  'create_participants_tsv:participantFileExist');
  end

  delete(output_filename);

end
