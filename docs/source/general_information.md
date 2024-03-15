# BIDS for MATLAB / Octave

This repository aims at centralising MATLAB/Octave tools to interact with
datasets conforming to the BIDS (Brain Imaging Data Structure) format.

For more information about BIDS, visit https://bids.neuroimaging.io/.

Join our chat on the
[BIDS-MATLAB channel](https://mattermost.brainhack.org/brainhack/channels/bids-matlab)
on the brainhack mattermost and our [google group](https://groups.google.com/g/bids-matlab).

See also [PyBIDS](https://github.com/bids-standard/pybids) for Python and the
[BIDS Starter Kit](https://github.com/bids-standard/bids-starter-kit).

## Installation, Features

Please see the [relevant sections of the README](https://github.com/bids-standard/bids-matlab)


## Usage

BIDS matlab is structured as package, so you can easily access functions in subfolders
that start with `+`.

To use the `+bids/layout.m` function:

```Matlab
BIDS = bids.layout('/home/data/ds000117');
bids.query(BIDS, 'subjects')
```

To use the `+bids/+util/jsondecode.m` function:

```Matlab
content = bids.util.jsondecode('/home/data/some_json_file.json');
```

A
[tutorials](https://github.com/bids-standard/bids-matlab/blob/main/lib/bids-matlab/demos/notebooks)
are available as a Jupyter Notebooks and scripts and can be run interactively via
[Binder](https://mybinder.org/v2/gh/bids-standard/bids-matlab/main?urlpath=demos).


### Reading and writing JSON files

If you are using MATLAB R2016b or newer, nothing else needs to be installed.

If you are using MATLAB R2016a or older, or using Octave, you need to install a
supported JSON library for your MATLAB or Octave. This can be any of:

- [JSONio](https://github.com/gllmflndn/JSONio) for MATLAB or Octave
- [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)

## Implementation

Starting point was `spm_BIDS.m` from [SPM12](https://github.com/spm/spm12)
([documentation](https://en.wikibooks.org/wiki/SPM/BIDS#BIDS_parser_and_queries))
reformatted in a `+bids` package with dependencies to other SPM functions
removed.
