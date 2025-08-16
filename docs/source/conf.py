# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys

sys.path.insert(0, os.path.abspath("../.."))


# -- Project information -----------------------------------------------------

project = "bids-matlab"
copyright = "2018, BIDS-MATLAB developers"
author = "BIDS-MATLAB developers"

# The full version, including alpha/beta/rc tags
with open("../../version.txt", encoding="utf-8") as version_file:
    release = version_file.read()


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "sphinxcontrib.matlab",
    "sphinx.ext.autodoc",
    "sphinx_copybutton",
    "myst_parser",
]
matlab_src_dir = os.path.dirname(os.path.abspath("../../+bids"))
primary_domain = "mat"

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates"]

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = "sphinx"

# The master toctree document.
master_doc = "index"

# source_suffix = ['.rst', '.md']
source_suffix = {'.rst': 'restructuredtext'}

autodoc_member_order = "bysource"


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
# html_static_path = ['_static']

html_sidebars = {
    "**": [
        "about.html",
        "navigation.html",
        "relations.html",  # needs 'show_related': True theme option to display
        "searchbox.html",
        "donate.html",
    ]
}

linkcheck_ignore = [
    "https://nl.mathworks.com/matlabcentral/fileexchange/93740-bids-matlab",
    "https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg",
    "https://allcontributors.org/docs/en/emoji-key",
    "https://mybinder.org/badge_logo.svg"
]

linkcheck_exclude_documents = [r".*/sg_execution_times.rst"]

linkcheck_allow_unauthorized = True
