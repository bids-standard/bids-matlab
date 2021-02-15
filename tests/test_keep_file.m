function test_suite = test_keep_file %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_keep_file_basic()

  file_struct = struct('suffix', 'bold', ...
                       'ext', '.nii.gz', ...
                       'entities', struct('task', 'balloon', ...
                                          'ses', '01', ...
                                          'sub', '02'));

  options = {'ses', {'01'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), true);

  options = {'ses', {'02'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), false);

  options = {'ses', {'01', '02'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), true);

  options = {'suffix', {'T1w'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), false);

  options = {'suffix', {'bold'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), true);

  options = {'suffix', {'bold'}
             'extension', {'.nii'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), false);

  options = {'suffix', {'T1w', 'bold'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), true);

  options = {'sub', {'02'}
             'ses', {'01'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), true);

  options = {'sub', {'02'}
             'ses', {'02'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), false);

  options = {'sub', {'02'}
             'ses', {'01'}
             'suffix', {'T1w'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), false);

  options = {'sub', {'02'}
             'task', {'balloon'}};
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), true);

  file_struct = struct('suffix', 'T1w', ...
                       'entities', struct('ses', '01', ...
                                          'sub', '02'));
  assertEqual(bids.internal.keep_file_for_query(file_struct, options), false);

end
