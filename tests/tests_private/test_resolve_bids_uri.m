function test_suite = test_resolve_bids_uri %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_resolve_bids_uri_legacy

  uris = {'', 'foo', 'func/sub-01_task-foo_bold.nii.gz'};
  layout = '';

  for i = 1:numel(uris)
    pth = bids.internal.resolve_bids_uri(uris{i}, layout);
    assertEqual(pth, uris{i});
  end

end

function test_resolve_bids_uri_basic

  uri = {'bids::sub-01/func/sub-01_task-foo_run-1_bold.nii', ...
         'bids::sub-01/func/sub-01_task-foo_run-2_bold.nii'};
  layout = struct('pth', pwd);

  pth = bids.internal.resolve_bids_uri(uri, layout);
  assertEqual(pth, ...
              {fullfile(pwd, 'sub-01', 'func', 'sub-01_task-foo_run-1_bold.nii'); ...
               fullfile(pwd, 'sub-01', 'func', 'sub-01_task-foo_run-2_bold.nii')});

end

function test_resolve_bids_uri_from_ds_desc

  uri = {'bids:deriv1:sub-01/func/sub-01_task-foo_space-MNI_desc-preproc_bold.nii'};
  layout = struct('pth', pwd,     ...
                  'description', struct('DatasetLinks',  ...
                                        struct('deriv1', 'derivatives/derivative1', ...
                                               'phantoms', 'file:///data/phantoms')));

  pth = bids.internal.resolve_bids_uri(uri, layout);
  assertEqual(pth, fullfile(pwd, ...
                            'derivatives', ...
                            'derivative1', ...
                            'sub-01', ...
                            'func', ...
                            'sub-01_task-foo_space-MNI_desc-preproc_bold.nii'));

end
