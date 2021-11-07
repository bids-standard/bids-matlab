function test_suite = test_demos %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_downloads()

  pth = bids.util.download_ds();
  rmdir(pth, 's');

  pth = bids.util.download_ds('out_path', pwd);
  rmdir(pth, 's');

end

function test_downloads_spm_facerep()

  if ~is_github_ci()

    bids.internal.ds_spm_face_rep(pwd);
    rmdir(fullfile(pwd, 'facerep'), 's');

    pth = bids.util.download_ds('source', 'spm', 'demo', 'facerep');
    rmdir(pth, 's');

  end

end
