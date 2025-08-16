# Contributing

**Welcome to the BIDS-MATLAB repository!**

_We're so excited you're here and want to contribute._

**Welcome to the BIDS Specification repository!**

_We're so excited you're here and want to contribute._

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

### Matlab code style guide and quality

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
[datalad handbook](http://handbook.datalad.org/en/latest/intro/installation.html#python-3-all-operating-systems).

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

### Running tests on the code

The unit and integration tests we have are in the [`tests` folder]'(./tests/)
and should be run with MoxUnit. For more information on the set up for the test,
see the [README in the tests folder](./tests/README.md).

If you are not sure what unit and integration tests are, check the chapter about
that in the
[Turing way](https://the-turing-way.netlify.app/reproducible-research/testing.html).

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

BIDS-MATLAB follows the
[all-contributors](https://github.com/kentcdodds/all-contributors)
specification, so we welcome and recognize all contributions from documentation
to testing to code development. You can see a list of current contributors in
the [README](./README.md).

Also make sure you add your information to the [CITATION.cff file](./CITATION.cff).

If you have made any type of contributions to BIDS-MATLAB, our team will add you
as a contributor (or ask to be added if we forgot).
