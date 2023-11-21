## Notebooks

[Tutorials](https://github.com/bids-standard/bids-matlab/blob/main/demos/notebooks/tutorial.ipynb)
are available as a Jupyter Notebook to be run with Octave and that can be run interactively via
[Binder](https://mybinder.org/v2/gh/bids-standard/bids-matlab/main?urlpath=demos).

There is also `.m` script equivalent for each tutorial that can be run with MATLAB.

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
