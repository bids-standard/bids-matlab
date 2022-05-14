function test_suite = test_download_ds %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_download_ds_basic()

  bu_folder = fixture_moae();

  pth = bids.util.download_ds('source', 'spm', ...
                              'demo', 'moae', ...
                              'force', true, ...
                              'verbose', false, ...
                              'delete_previous', true);

  bids.layout(pth);

  teardown_moae(bu_folder);

end
