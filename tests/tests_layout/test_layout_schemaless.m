function test_suite = test_layout_schemaless %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_layout_no_schema_no_ses_in_filename()

  % filter for speed
  filter = struct('sub', {{'01'}});

  verbose = false;

  bids_dir = tempname();

  % create dummy file
  copyfile(fullfile(get_test_data_dir(), 'ds006'), bids_dir);
  ses_folder = fullfile(bids_dir, 'sub-01', 'ses-post', 'anat');
  copyfile(fullfile(ses_folder, 'sub-01_ses-post_T1w.nii.gz'), ...
           fullfile(ses_folder, 'sub-01_T1w.nii.gz'));

  BIDS = bids.layout(bids_dir, ...
                     'verbose', verbose, ...
                     'index_dependencies', false, ...
                     'use_schema', true, ...
                     'filter', filter);

  files = bids.query(BIDS, 'data', 'sub', '01',  'suffix', 'T1w');
  assert(numel(files) == 2);

  BIDS = bids.layout(bids_dir, ...
                     'verbose', verbose, ...
                     'index_dependencies', false, ...
                     'use_schema', false, ...
                     'filter', filter);

  files = bids.query(BIDS, 'data', 'sub', '01', 'suffix', 'T1w');
  assert(numel(files) == 3);

end

function test_layout_empty_subject_folder_allowed_when_schemaless()

  verbose = false;

  bids.util.mkdir(fullfile(pwd, 'tmp/sub-01'));
  bids.layout(fullfile(pwd, 'tmp'), 'use_schema', false, 'verbose', verbose);
  rmdir(fullfile(pwd, 'tmp'), 's');
end
