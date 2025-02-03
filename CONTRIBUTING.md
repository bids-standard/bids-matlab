# Contributing to BIDS-MATLAB

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

## Updating the bids-schema

The schema of the BIDS specification is available as a
[set of yaml files in the bids-standards repository](https://github.com/bids-standard/bids-specification/blob/master/CONTRIBUTING.md#updating-the-schema).

A JSON version is also available here: https://bids-specification.readthedocs.io/en/latest/schema.json

The latest version can be obtained by running the following command:

```bash
make update_schema
```

A new version of the schema is fetched automatically regularly via continuous integration
(see the [github action](.github/workflows/update_schema.yml)) when pushing to the repo
or opening a pull-request.

## release protocol

- [ ] create a dedicated branch for the release candidate
- [ ] update version in `citation.cff`
- [ ] documentation related
  - [ ] ensure the documentation is up to date
  - [ ] make sure the doc builds correctly and fix any error
- [ ] update jupyter books
- [ ] update binder
- [ ] update changelog
  - [ ] change from `[unreleased]` to the version number
  - [ ] remove unused sections (like `security`)
- [ ] run `make release`
- [ ] open a pull request (PR) from this release candidate branch targeting the default branch
- [ ] fix any remaining failing continuous integration (test, markdown and code linting...)
- [ ] merge to default branch
- [ ] create a github tagged release
- [ ] after release
  - [ ] set version in `citation.cff` to dev
  - [ ] update changelog
    - [ ] add an `[unreleased]` section
