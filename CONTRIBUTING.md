# Contributing

**Welcome to the bids-matlab repository!**

We're so excited you're here and want to contribute.

We hope that these guidelines are designed to make it as easy as possible to get involved.
If you have any questions that aren't discussed below, please let us know
by [opening an issue](https://github.com/bids-standard/bids-matlab/issues/new).

If you are not familiar with Git and GitHub,
check our [generic contributing guidelines](https://bids-website.readthedocs.io/en/latest/collaboration/bids_github/CONTRIBUTING.html).

If you want to contribute to the BIDS matlab codebase,
make sure you also read the instructions below.

## Style guide

### Writing in markdown

For anything that is in markdown we have a soft rule that aims to enforce
"hardline wrapping" to make sure that lines wrap around at a certain line
length. The main reason is that it makes it easier for reviewers to detect the
changes so in a whole paragraph.

Some editors can automatically enforce hard-line wrapping with some linter like
`Prettier` so that you are always only a shortcut away from a tidy document. See
an example with visual-studio code
[here](https://glebbahmutov.com/blog/configure-prettier-in-vscode/#saving-without-formatting).

### MATLAB code style guide and quality

We use the [MISS_HIT linter](https://github.com/florianschanda/miss_hit/) to
automatically enforce / fix some code style issues and check for
[code quality](https://the-turing-way.netlify.app/reproducible-research/code-quality.html).

The linter is a Python package that can be installed with:

```
pip3 install -r requirements.txt
```

<details><summary> <b>💻 Installing Python</b> </font> </summary><br>

If you do not have Python on your computer, we warmly recommend the install
instruction from the
[datalad handbook](http://handbook.datalad.org/en/latest/intro/installation.html).

</details>

The rules followed by MISS_HIT are in the
[MISS_HIT configuration file](./miss_hit.cfg).

To check the code style of the whole repository, you can can simply type:

```bash
mh_style .
```

Some styling issues can be automatically fixed by using the `--fix` flag. You
might need to rerun this command several times if there are a lot of issues.

```bash
mh_style . --fix
```

Code quality can be checked with:

```bash
mh_metric .
```

To see only the issues that "break" the code quality rules set in the
configuration file, type:

```bash
mh_metric . --ci
```

The code style and quality is also checked during the continuous integration.

For more information about MISS_HIT see its
[documentation](https://florianschanda.github.io/miss_hit/).

## Running tests on the code

We use a series of unit and integration tests to make sure the code behaves as
expected and to also help in development.
The unit and integration tests we have are in the [`tests` folder]'(./tests/)
and should be run with [MOxUnit](https://moxunit.github.io/MOxUnit/).

If you are not sure what unit and integration tests are, check the chapter about
that in the
[Turing way](https://the-turing-way.netlify.app/reproducible-research/testing.html).

### Install MOxUnit

You need to install
[MOxUnit for MATLAB and Octave](https://github.com/MOxUnit/MOxUnit) to run the
tests.

Note the install procedure will require you to have
[git](https://git-scm.com/downloads) installed on your computer.
If you don't,
you can always download the MOxUnit code with this
[link](https://github.com/MOxUnit/MOxUnit/archive/master.zip).

Run the following from a terminal in the folder where you want to install MOxUnit.
The `make install` command will find MATLAB / Octave on your system and
make sure it plays nice with MOxUnit.

NOTE: only type in the terminal what is after the `$` sign:

```bash
# get the code for MOxUnit with git
git clone https://github.com/MOxUnit/MOxUnit.git
# enter the newly created folder and set up MOxUnit
cd MOxUnit
make install
```

If you want to check the code coverage on your computer, you can also install
[MOcov for matlab and octave](https://github.com/MOcov/MOcov).
Note that this is
also part of the continuous integration of the bids-matlab, so you don't need to
do this.

### Install the test data

To run the tests we used the examples data sets from the
[bids-examples repository](https://github.com/bids-standard/bids-examples)
and also create some dummy datasets.

This requires python to be installed as a python script is used
to generate the dummy datasets.

```bash
cd tests
make data
```

or

```bash
cd tests
pip install pandas
python create_dummy_data_set.py
git clone https://github.com/bids-standard/bids-examples.git --depth 1
```

### Add helper functions to the path

There are a some help functions you need
to add to the MATLAB / Octave path to run the tests:

```matlab
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

### Adding more tests

You can use the following function template to write more tests.

```matlab
function test_suite = test_functionToTest()
    % This top function is necessary for MOxUnit to run tests.
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


## Building the documentation

The documentation is generated with the `Sphinx` python package
and the help section of all the functions and classes
is used to create the code documentation
thanks to the `sphinxcontrib-matlabdomain` sphinx extension.

### Install the dependencies

```bash
pip install -r requirements.txt
```

### Build the documentation locally

From the `docs` directory run:

```bash
make html
```

or if you do not have make:

```bash
sphinx-build -b html source build
```

This will build an html version of the doc in the `build` folder.

### reStructured text markup

reStructured text mark up primers:

-   on the [sphinx site](https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html)

-   more
    [python oriented](https://pythonhosted.org/an_example_pypi_project/sphinx.html)

-   typical doc strings templates
    -   [google way](https://www.sphinx-doc.org/en/master/usage/extensions/example_google.html)
    -   [numpy](https://www.sphinx-doc.org/en/master/usage/extensions/example_numpy.html#example-numpy)

### "Templates"

If you need to create a new page in the doc to automatically
document your code, here is a 'template' to help you get started.

```rst

.. automodule:: +bids.folder_name .. <-- This is necessary for auto-documenting the rest

.. autofunction:: function to document

```

To get the filenames of all the functions in a folder to add them to a file:

``` bash
ls -l +bids/*.m | cut -c42- | rev | cut -c 3- | rev | sed s/+bids/".. autofunction::"/g
```

Increase the `42` to crop more characters at the beginning.

Change the `3` to crop more characters at the end.

## How the decision to merge a pull request is made?

The decision-making rules are outlined in
[DECISION-MAKING.md](DECISION-MAKING.md).

## Recognizing contributions

bids-matlab follows the
[all-contributors](https://github.com/kentcdodds/all-contributors)
specification, so we welcome and recognize all contributions from documentation
to testing to code development. You can see a list of current contributors in
the [README](./README.md).

Also make sure you add your information to the [CITATION.cff file](./CITATION.cff).

If you have made any type of contributions to bids-matlab, our team will add you
as a contributor (or ask to be added if we forgot).

You can also add yourself as a contributor as follows:

Make sure you have Node.js and npm installed on your computer, then install the
all-contributors-cli tool with:

```bash
npm install -g all-contributors-cli
```

Add yourself to [.all-contributorsrc](./.all-contributorsrc) and then run:

```bash
npx all-contributors generate
```

Make a pull request with the changes to the .all-contributorsrc, README.md, and
CITATION.cff files.
