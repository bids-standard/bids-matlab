function test_suite = test_create_readme %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_readme_basic()

  source_ds = fullfile(get_test_data_dir(), 'ds210');
  tmp_path = temp_dir();
  copyfile(source_ds, tmp_path);
  if bids.internal.is_octave()
    bids_path = fullfile(tmp_path, 'ds210');
  else
    bids_path = tmp_path;
  end

  bids.util.create_readme(bids_path, false, ...
                          'tolerant', true, ...
                          'verbose', false);

  assertEqual(exist(fullfile(bids_path, 'README.md'), 'file'), 2);

end

function test_create_readme_warning_already_present()

  skip_if_octave('mixed-string-concat warning thrown');

  bids_path = fullfile(get_test_data_dir(), 'ds116');

  assertWarning(@()bids.util.create_readme(bids_path, false, ...
                                           'tolerant', true, ...
                                           'verbose', true), ...
                'create_readme:readmeAlreadyPresent');

end

function test_create_readme_warning_layout()

  foo = struct('spam', 'egg');

  assertWarning(@()bids.util.create_readme(foo, false, ...
                                           'tolerant', true, ...
                                           'verbose', true), ...
                'create_readme:notBidsDatasetLayout');

end
