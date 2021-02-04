function test_suite = test_file_utils %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_file_utils_basic()

  %% test to get certain part of a filename
  % {'path', 'basename', 'ext', 'filename', 'cpath', 'fpath'}

  str = fullfile('folder', 'filename.extension');

  p = bids.internal.file_utils(str, 'path');
  assert(isequal(p, 'folder'));

  p = bids.internal.file_utils(str, 'fpath');
  assert(isequal(p, fullfile(pwd, 'folder')));

  filename = bids.internal.file_utils(str, 'basename');
  assert(isequal(filename, 'filename'));

  ext = bids.internal.file_utils(str, 'ext');
  assert(isequal(ext, 'extension'));

  str = fullfile('folder', 'subfolder', '..', 'filename.extension');
  cpath = bids.internal.file_utils(str, 'cpath');
  assert(isequal(cpath, ...
                 fullfile(pwd, 'folder', 'filename.extension')));

  %% test to set certain part of a filename
  % {'path', 'basename', 'ext', 'filename', 'prefix', 'suffix'}

  str = fullfile('folder', 'filename.extension');

  new_str = bids.internal.file_utils(str, 'ext', 'newext');
  assert(isequal(new_str, fullfile('folder', 'filename.newext')));

  new_str = bids.internal.file_utils(str, 'basename', 'new_name');
  assert(isequal(new_str, fullfile('folder', 'new_name.extension')));

  new_str = bids.internal.file_utils(str, 'filename', 'new_name.newext');
  assert(isequal(new_str, fullfile('folder', 'new_name.newext')));

  new_str = bids.internal.file_utils(str, 'prefix', 'pre_');
  assert(isequal(new_str, fullfile('folder', 'pre_filename.extension')));

  new_str = bids.internal.file_utils(str, 'suffix', '_suffix');
  assert(isequal(new_str, fullfile('folder', 'filename_suffix.extension')));

  new_str = bids.internal.file_utils(str, 'path', fullfile(pwd, 'new_folder'));
  assert(isequal(new_str, fullfile(pwd, 'new_folder', 'filename.extension')));

  new_str = bids.internal.file_utils(str, ...
                                     'prefix', 'pre_', ...
                                     'suffix', '_suffix');
  assert(isequal(new_str, fullfile('folder', 'pre_filename_suffix.extension')));

  %% test to list files

  test_directory = fileparts(mfilename('fullpath'));

  file = bids.internal.file_utils('List', ...
                                  test_directory, ...
                                  '^test_file_utils.m$');
  assert(isequal(file, 'test_file_utils.m'));

  file = bids.internal.file_utils('List', ...
                                  test_directory, ...
                                  '^.*.md$');
  assert(isequal(file, 'README.md'));

  directory = bids.internal.file_utils('List', ...
                                       test_directory, ...
                                       'dir', ...
                                       '^data$');
  assert(isequal(directory, 'data'));

  fp_file = bids.internal.file_utils('FPList', ...
                                     test_directory, ...
                                     '^test_file_utils.m$');
  assert(isequal(fp_file, [mfilename('fullpath') '.m']));

  fp_directory = bids.internal.file_utils('FPList', ...
                                          test_directory, ...
                                          'dir', ...
                                          '^data$');
  assert(isequal(fp_directory, ...
                 fullfile(test_directory, 'data')));

end
