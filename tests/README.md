# Tests for bids-matlab

## How to run the tests

- Install [MOxUnit for matlab and octave](https://github.com/MOxUnit/MOxUnit)
  to run the tests

- Install [MOcov for matlab and octave](https://github.com/MOcov/MOcov) to get
  the code coverage

- Make sure that you have clone the bids-examples repo in the `tests` folder:

```bash
cd tests
git clone git://github.com/bids-standard/bids-examples.git --depth 1
```

- From the root folder, run `moxunit_runtests tests` or
  `moxunit_runtests tests -verbose` to run the tests.

This should tell you which tests pass or fail.

## Adding more tests

You can use the following function template to write more tests.

```matlab
function test_suite = test_functionToTest()
    % This top function is necessary for mox unit to run tests.
    % DO NOT CHANGE IT except to adapt the name of the function.
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions(); %#ok<*NASGU>
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;
end

function test_function_to_test_basic()

    %% set up


    %% data to test against


    %% test
    % assertTrue( );
    % assertFalse( );
    % assertEqual( );

end


function test_function_to_test_other_usecase()

    %% set up


    %% data to test against


    %% test
    % assertTrue( );
    % assertFalse( );
    % assertEqual( );

end

```
