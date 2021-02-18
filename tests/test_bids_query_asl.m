function test_suite = test_bids_query_asl %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_asl_basic()
  %
  %   asl queries
  %

  pth_bids_example = get_test_data_dir();

  %% 'asl001'
  BIDS = bids.layout(fullfile(pth_bids_example, 'asl001'));

  modalities = {'anat', 'perf'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'asl', 'aslcontext', 'asllabeling'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  BIDS.subjects(1).perf(1);

  filename = bids.query(BIDS, 'data', 'sub', 'Sub103', 'suffix', 'asl');
  basename = bids.internal.file_utils(filename, 'basename');
  assertEqual(basename, {'sub-Sub103_asl.nii'});

  meta = bids.query(BIDS, 'metadata', 'sub', 'Sub103', 'suffix', 'asl');

  dependencies = bids.query(BIDS, 'dependencies', 'sub', 'Sub103', 'suffix', 'asl');
  assertEqual(dependencies.labeling_image.filename, 'sub-Sub103_asllabeling.jpg');
  dependencies.context;
  dependencies.m0;

  %% 'asl002'
  BIDS = bids.layout(fullfile(pth_bids_example, 'asl002'));

  modalities = {'anat', 'perf'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'asl', 'aslcontext', 'asllabeling', 'm0scan'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  filename = bids.query(BIDS, 'data', 'sub', 'Sub103', 'suffix', 'm0scan');
  basename = bids.internal.file_utils(filename, 'basename');
  assertEqual(basename, {'sub-Sub103_m0scan.nii'});

  assert(isfield(BIDS.subjects.perf(4), 'intended_for'));

  %% 'asl003'
  BIDS = bids.layout(fullfile(pth_bids_example, 'asl003'));

  modalities = {'anat', 'perf'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'asl', 'aslcontext', 'asllabeling', 'm0scan'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  %% 'asl004'
  BIDS = bids.layout(fullfile(pth_bids_example, 'asl004'));

  modalities = {'anat', 'fmap', 'perf'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  suffixes = {'T1w', 'asl', 'aslcontext', 'asllabeling', 'm0scan'};
  assertEqual(bids.query(BIDS, 'suffixes'), suffixes);

  filename = bids.query(BIDS, 'data', 'suffix', 'm0scan', 'dir', 'pa');
  basename = bids.internal.file_utils(filename, 'basename');
  assertEqual(basename, {'sub-Sub1_dir-pa_m0scan.nii'});

  assert(isfield(BIDS.subjects.fmap, 'intended_for'));
  assert(isfield(BIDS.subjects.perf(4), 'intended_for'));

end
