function test_suite = test_bids_query_mrs %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_asl_basic_2dmrsi()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'mrs_2dmrsi'));

  modalities = {'anat', 'mrs'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'mrsi'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  assertEqual(numel(bids.query(BIDS, 'data')), 32);

  filename = bids.query(BIDS, 'data', 'sub', '01', 'suffix', 'mrsi');
  basename = bids.internal.file_utils(filename, 'basename');
  assertEqual(basename, {'sub-01_run-1_mrsi.nii'
                         'sub-01_run-2_mrsi.nii'
                         'sub-01_run-3_mrsi.nii'});

end

function test_bids_query_asl_basic_biggaba()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'mrs_biggaba'));

  modalities = {'anat', 'mrs'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w',    'mrsref',    'svs'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  assertEqual(numel(bids.query(BIDS, 'data')), 84);

end

function test_bids_query_asl_basic_fmrs()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'mrs_fmrs'), 'use_schema', false);

  modalities = {'anat', 'mrs'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w',  'events',   'mrsref',   'svs'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  assertEqual(numel(bids.query(BIDS, 'data')), 90);

  metadata = bids.query(BIDS, 'metadata', 'sub', '01', 'suffix', 'svs');

  metadata{1}.ReferenceSignal;
  bids.internal.resolve_bids_uri(metadata{1}.ReferenceSignal, BIDS);

end
