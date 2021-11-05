function test_suite = test_replace_placeholders %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_replace_placeholders_basic

  boilerplate_text = '{{Manufacturer}} and {{ManufacturersModelName}} and {{SoftwareVersions}}';
  metadata.SoftwareVersions = 'v0.1.0';
  boilerplate_text = bids.internal.replace_placeholders(boilerplate_text, metadata);

  expected = '{{Manufacturer}} and {{ManufacturersModelName}} and v0.1.0';

  assertEqual(boilerplate_text, expected);

end
