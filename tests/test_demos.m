function test_suite = test_demos %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_downloads()

  cfg = set_test_cfg();

  pth = bids.util.download_ds('verbose', cfg.verbose);
  rmdir(pth, 's');

  pth = bids.util.download_ds('out_path', fullfile(pwd, 'output'), ...
                              'verbose', cfg.verbose);
  rmdir(pth, 's');

end

function test_downloads_spm_facerep()

  cfg = set_test_cfg();

  if ~bids.internal.is_github_ci()

    bids.internal.ds_spm_face_rep(pwd);
    rmdir(fullfile(pwd, 'facerep'), 's');

    pth = bids.util.download_ds('source', 'spm', ...
                                'demo', 'facerep', ...
                                'verbose', cfg.verbose);
    rmdir(pth, 's');

  end

end
