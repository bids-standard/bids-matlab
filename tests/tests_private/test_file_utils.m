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
  assertEqual(p, 'folder');

  p = bids.internal.file_utils(str, 'fpath');
  assertEqual(p, fullfile(pwd, 'folder'));

  filename = bids.internal.file_utils(str, 'basename');
  assertEqual(filename, 'filename');

  ext = bids.internal.file_utils(str, 'ext');
  assertEqual(ext, 'extension');

  str = fullfile('folder', 'subfolder', '..', 'filename.extension');
  cpath = bids.internal.file_utils(str, 'cpath');
  assertEqual(cpath, ...
              fullfile(pwd, 'folder', 'filename.extension'));

  %% test to set certain part of a filename
  % {'path', 'basename', 'ext', 'filename', 'prefix', 'suffix'}

  str = fullfile('folder', 'filename.extension');

  new_str = bids.internal.file_utils(str, 'ext', 'newext');
  assertEqual(new_str, fullfile('folder', 'filename.newext'));

  new_str = bids.internal.file_utils(str, 'basename', 'new_name');
  assertEqual(new_str, fullfile('folder', 'new_name.extension'));

  new_str = bids.internal.file_utils(str, 'filename', 'new_name.newext');
  assertEqual(new_str, fullfile('folder', 'new_name.newext'));

  new_str = bids.internal.file_utils(str, 'prefix', 'pre_');
  assertEqual(new_str, fullfile('folder', 'pre_filename.extension'));

  new_str = bids.internal.file_utils(str, 'suffix', '_suffix');
  assertEqual(new_str, fullfile('folder', 'filename_suffix.extension'));

  new_str = bids.internal.file_utils(str, 'path', fullfile(pwd, 'new_folder'));
  assertEqual(new_str, fullfile(pwd, 'new_folder', 'filename.extension'));

  new_str = bids.internal.file_utils(str, ...
                                     'prefix', 'pre_', ...
                                     'suffix', '_suffix');
  assertEqual(new_str, fullfile('folder', 'pre_filename_suffix.extension'));

  %% test to list files

  file = bids.internal.file_utils('List', ...
                                  fullfile(fileparts(mfilename('fullpath'))), ...
                                  '^test_file_utils.m$');
  assertEqual(file, 'test_file_utils.m');

  this_dir = fullfile(fileparts(mfilename('fullpath')));
  parent_dir = fullfile(this_dir, '..');

  file = bids.internal.file_utils('List', ...
                                  parent_dir, ...
                                  '^.*.md$');
  assertEqual(file, 'README.md');

  directory = bids.internal.file_utils('List', ...
                                       parent_dir, ...
                                       'dir', ...
                                       '^data$');
  assertEqual(directory, 'data');

  fp_file = bids.internal.file_utils('FPList', ...
                                     this_dir, ...
                                     '^test_file_utils.m$');
  assertEqual(fp_file, [mfilename('fullpath') '.m']);

  dir_to_create = fullfile(this_dir, 'data');
  mkdir(dir_to_create);
  fp_directory = bids.internal.file_utils('FPList', ...
                                          this_dir, ...
                                          'dir', ...
                                          '^data$');
  assertEqual(fp_directory, ...
              fullfile(this_dir, 'data'));
  set_test_cfg();
  rmdir(dir_to_create, 's');

end
