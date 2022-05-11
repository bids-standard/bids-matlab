function test_suite = test_download_ds %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_download_ds_basic()

  pth = bids.util.download_ds('source', 'spm', ...
                              'demo', 'moae', ...
                              'force', false, ...
                              'verbose', false);

  % rmdir(fullfile(pth, 'MoAEpilot'), 's');

end
