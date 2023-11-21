function test_suite = test_bids_query_microscopy %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_bids_query_microscopy_basic()

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'micr_SEM'), ...
                     'index_dependencies', false);

  data = bids.query(BIDS, 'data');
  assertEqual(numel(data), 6);

  BIDS = bids.layout(fullfile(get_test_data_dir(), 'micr_SPIM'), ...
                     'index_dependencies', false);

  data = bids.query(BIDS, 'data');
  assertEqual(numel(data), 11);

  samples = bids.query(BIDS, 'samples');
  assertEqual(samples, {'A', 'B'});

  chunks = bids.query(BIDS, 'chunks');
  assertEqual(chunks, {'01', '02', '03', '04'});

  stains = bids.query(BIDS, 'stains');
  assertEqual(stains, {'LFB'});

  % make sure we can use indices for chunks
  data = bids.query(BIDS, 'data', 'sample', 'A', 'chunk', 1, 'ext', '.ome.tif');
  filename = bids.internal.file_utils(data{1}, 'filename');
  assertEqual(filename, 'sub-01_sample-A_stain-LFB_chunk-01_SPIM.ome.tif');

end
