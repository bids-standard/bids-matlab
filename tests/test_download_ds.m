function test_suite = test_download_ds %#ok<*STOUT>

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_download_ds_smoke()

  output_dir = bids.util.download_ds('source', 'spm', ...
                                     'demo', 'moae', ...
                                     'out_path', fullfile(bids.internal.root_dir(), 'tmp'), ...
                                     'force', true, ...
                                     'verbose', false, ...
                                     'delete_previous', true);

end
