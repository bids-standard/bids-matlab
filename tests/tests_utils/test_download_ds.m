function test_suite = test_download_ds %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_download_ds_basic()

  target_dir = bids.internal.file_utils(fullfile(get_test_data_dir(), ...
                                                 '..', '..', ...
                                                 'demos', 'spm', 'moae'), ...
                                        'cpath');

  % back up content
  tmp = tempname;
  copyfile(target_dir, tmp);

  pth = bids.util.download_ds('source', 'spm', ...
                              'demo', 'moae', ...
                              'force', true, ...
                              'verbose', false, ...
                              'delete_previous', true);

  bids.layout(target_dir);

  % remove data
  rmdir(pth, 's');

  % bring backup back
  copyfile(tmp, target_dir);

end
