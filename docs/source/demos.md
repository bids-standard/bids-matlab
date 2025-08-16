# Demos

Several demos are available in [`demo` folder](https://github.com/bids-standard/bids-matlab/blob/main/demos/).

## Notebooks

Several demos in the [`demo` folder](https://github.com/bids-standard/bids-matlab/blob/main/demos/notebooks) are available
as a Jupyter Notebook to be run with Octave and that can be run interactively via
[Binder](https://mybinder.org/v2/gh/bids-standard/bids-matlab/main?urlpath=demos)
or locally.
There is also `.m` script equivalent for each tutorial that can be run with MATLAB.

### Pre-requesite

To run some of the scripts or notebooks,
you need to install the bids examples repository
in the `demos/notebooks` directory.

Run the following command in the terminal:

```bash
git clone https://github.com/bids-standard/bids-examples.git --depth 1
```

### Running the notebooks with Octave

1.  Make sure that you have Octave installed.

1.  Install jupyter lab and the the [Octave kernel](https://pypi.org/project/octave-kernel/):

    ```bash
    pip install jupyterlab octave_kernel
    ```

1.  Run `jupyter lab` in your terminal.
    Open a a notebook and `Octave` should appear on the list of available kernels.

1. Make sure you have bids-matlab in the path and JSONio.


## SPM

This shows how to use BIDS-MATLAB with SPM12 by running some of the tutorials
from the SPM website by relying on BIDS-MATLAB for file querying.

There is also an example of how to extract confound information from fmriprep datasets
to make it easier to analyse them with SPM.

The output should have a BIDS like structure like this:

```bash
spm12
├── CHANGES
├── dataset_description.json
├── README
└── sub-01
    └── stats
        ├── sub-01_task-facerepetition_confounds.mat
        └── sub-01_task-facerepetition_confounds.tsv
```

## Transformers

Small demo on how to use transformers to modify the content of events TSV files
to be used with the BIDS statistical model.
