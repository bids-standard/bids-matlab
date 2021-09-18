# Setting up sphinx to create a matlab doc

## Set up virtual environment

```bash
virtualenv -p /usr/bin/python3.8 env
source env/bin/activate

pip install -r requirements.txt
```

## Quick start on the doc

See the [sphinx doc](https://www.sphinx-doc.org/en/master/usage/quickstart.html)
for more.

This
[blog post](https://medium.com/@richdayandnight/a-simple-tutorial-on-how-to-document-your-python-project-using-sphinx-and-rinohtype-177c22a15b5b)
is also useful.

```bash
cd docs
sphinx-quickstart # launch a basic interactive set up of sphinx
```

Answer the questions on prompt.

## Setting up conf.py for matlab doc

Following the documentation from
[matlabdomain for sphinx](https://github.com/sphinx-contrib/matlabdomain).

Specify the extensions you are using:

```python
extensions = [
    'sphinxcontrib.matlab',
    'sphinx.ext.autodoc']
```

`matlab_src_dir` in `docs/source/conf.py` should have the path (relative to
`conf.py`) to the folder containing your matlab code:

```python
matlab_src_dir = os.path.dirname(os.path.abspath('../../src'))
```

## reStructured text markup

reStructured text mark up primers:

-   on the [sphinx site](https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html)

-   more
    [python oriented](https://pythonhosted.org/an_example_pypi_project/sphinx.html)

-   typical doc strings templates
    -   [google way](https://www.sphinx-doc.org/en/master/usage/extensions/example_google.html)
    -   [numpy](https://www.sphinx-doc.org/en/master/usage/extensions/example_numpy.html#example-numpy)

## "Templates"


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

## Build the documentation locally

From the `docs` directory:

```bash
sphinx-build -b html source build
```

This will build an html version of the doc in the `build` folder.

## Build the documentation with Read the Docs

Add a [`.readthedocs.yml`](../.readthedocs.yml) file in the root of your repo.

See [HERE](https://docs.readthedocs.io/en/stable/config-file/v2.html) for
details.

You can then trigger the build of the doc by going to the
[read the docs website](https://readthedocs.org).

You might need to be added as a maintainer of the doc.

The doc can be built from any branch of a repo.
