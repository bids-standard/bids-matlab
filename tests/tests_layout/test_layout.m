function test_suite = test_layout %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_layout_empty_subject_folder_allowed_when_schemaless()

  verbose = true;

  mkdir tmp;
  mkdir tmp/sub-01;
  bids.layout(fullfile(pwd, 'tmp'), 'use_schema', false, 'verbose', verbose);
  rmdir(fullfile(pwd, 'tmp'), 's');
end

function test_layout_smoke_test()

  verbose = true;

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'genetics_ukbb'), 'verbose', verbose);

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds210'), 'verbose', verbose);

end
