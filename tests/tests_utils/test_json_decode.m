function test_suite = test_json_decode %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_json_decode_file_not_found()

  % write dummy faulty json

  filename = fullfile(temp_dir, 'foo.json');
  assertExceptionThrown(@() bids.util.jsondecode(filename), ...
                        'jsondecode:FileNotFound');

end

function test_json_decode_parse_error()

  % write dummy faulty json

  filename = fullfile(temp_dir, 'wrong.json');
  fid = fopen(filename, 'Wt');
  fprintf(fid, '{"foo": "bla"');
  fclose(fid);

  assertWarning(@() bids.util.jsondecode(filename), ...
                'jsondecode:CannotReadJson');

end
