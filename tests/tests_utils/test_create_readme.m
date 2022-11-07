function test_suite = test_create_readme %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_create_readme_warning()

  foo = struct('spam', 'egg');

  if ~bids.internal.is_octave()
    assertWarning(@()bids.util.create_readme(foo, false, ...
                                             'tolerant', true, ...
                                             'verbose', true), ...
                  'create_readme:notBidsDatasetLayout');
  end

end
