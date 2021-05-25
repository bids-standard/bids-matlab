# Tests for bids-matlab

We use a series of unit and integration tests to make sure the code behaves as
expected and to also help in development.

If you are not sure what unit and integration tests are, check the excellent
chapter about that in the
[Turing way](https://the-turing-way.netlify.app/reproducible-research/testing.html).

## How to run the tests

### Install MoxUnit

You need to install
[MOxUnit for matlab and octave](https://github.com/MOxUnit/MOxUnit) to run the
tests.

Note the install procedure will require you to have
[git](https://git-scm.com/downloads) installed on your computer. If you don't,
you can always download the MoxUnit code with this
[link](https://github.com/MOxUnit/MOxUnit/archive/master.zip).

Run the following from a terminal in the folder where you want to install
MOxUnit. The `make install` command will find Matlab / Octave on your system and
make sure it plays nice with MoxUnit.

NOTE: only type in the terminal what is after the `$` sign:

```bash
# get the code for MOxUnit with git
git clone https://github.com/MOxUnit/MOxUnit.git
# enter the newly created folder and set up MoxUnit
cd MOxUnit
make install
```

If you want to check the code coverage on your computer, you can also install
[MOcov for matlab and octave](https://github.com/MOcov/MOcov). Note that this is
also part of the continuous integration of the bids-matlab, so you don't need to
do this.

### Install the test data

To run the tests we used the examples data sets from the
[bids-examples repository](https://github.com/bids-standard/bids-examples).

The tests won't run unless you have a copy of that repository in the `tests`
folder:

```bash
cd tests
git clone git://github.com/bids-standard/bids-examples.git --depth 1
```

#### Datasets with content

The function `download_moae_ds.m` will download a lightweight dataset from the
SPM website.

To get more complex data sets, to test things you can use datalad.

```bash
mkdir data
datalad clone https://github.com/OpenNeuroDatasets/ds000001.git
datalad get ds000001/sub-01/

datalad clone https://github.com/OpenNeuroDatasets/ds000117.git
datalad get ds000117/sub-01/ses-mri/func
datalad get ds000117/sub-01/ses-mri/fmap


```

## Add helper functions to the path

There are a some help functions you need to add to the Matlab / Octave path to
run the tests:

```
addpath(fullfile('tests', 'utils'))
```

### Run the tests

From the root folder of the bids-matlab folder, you can run the test with one
the following commands.

```bash
moxunit_runtests tests

# Or if you want more feedback
moxunit_runtests tests -verbose
```

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

### Timing

If you need to load a dummy datasets check the `layout_timing` function as it as
a list of all the bids-matlab datasets and how loing it takes (more or less) to
run layout on each.
