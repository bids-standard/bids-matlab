function test_suite = test_update_struct %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;

end

function test_main_func()

  % testing with parameters
  js = struct([]);
  js = bids.util.update_struct(js, 'key_a', 'val_a', 'key_b', 'val_b');
  assertTrue(isfield(js, 'key_a'));
  assertTrue(isfield(js, 'key_b'));
  assertEqual(js.key_a, 'val_a');
  assertEqual(js.key_b, 'val_b');

  % testing with struct
  test_struct.key_c = 'val_c';

  js = bids.util.update_struct(js, test_struct);
  assertTrue(isfield(js, 'key_c'));
  assertEqual(js.key_c, 'val_c');

  % testing update and removal of field
  js = bids.util.update_struct(js, 'key_c', [], 'key_a', 'val_a2');
  assertFalse(isfield(js, 'key_c'));
  assertEqual(js.key_a, 'val_a2');

  % testing concatenating as string cell
  js = bids.util.update_struct(js, 'key_b-add', 'val_b2');
  assertEqual(js.key_b, {'val_b'; 'val_b2'});

  % testing concatenating numericals
  js = bids.util.update_struct(js, 'key_b-add', 3);
  assertEqual(js.key_b, {'val_b'; 'val_b2'; 3});
end

function test_exceptions()
  % Invalid input
  assertExceptionThrown(@() bids.util.update_struct(struct([]), 'key_b-add'), ...
                        'update_struct:invalidInput');
  assertExceptionThrown(@() bids.util.update_struct(struct([]), ...
                                                    'key_b-add', [], ...
                                                    'key_c'), ...
                        'update_struct:structError');
end
