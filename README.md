# BIDS for MATLAB / Octave
[![Build Status](https://travis-ci.com/bids-standard/bids-matlab.svg?branch=master)](https://travis-ci.com/bids-standard/bids-matlab)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/bids-standard/bids-matlab/master?filepath=examples/tutorial.ipynb)

This repository aims at centralising MATLAB/Octave tools to interact with datasets conforming to the BIDS (Brain Imaging Data Structure) format.

For more information about BIDS, visit https://bids.neuroimaging.io/.

See also [PyBIDS](https://github.com/bids-standard/pybids) for Python and the [BIDS Starter Kit](https://github.com/bids-standard/bids-starter-kit).

## Installation

Download this repository and add it to your MATLAB/Octave path.

```Matlab
unzip('https://github.com/bids-standard/bids-matlab/archive/master.zip');
addpath('bids-matlab-master');
```
If your version of MATLAB/Octave does not support JSON natively, please also install [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/) or [JSONio](https://github.com/gllmflndn/JSONio).

## Usage

```Matlab
BIDS = bids.layout('/home/data/ds000117');
bids.query(BIDS, 'subjects')
```

A [tutorial](https://github.com/bids-standard/bids-matlab/blob/master/examples/tutorial.ipynb) is available as a Jupyter Notebook and can be run interactively via [Binder](https://mybinder.org/v2/gh/bids-standard/bids-matlab/master?filepath=examples/tutorial.ipynb).

## Implementation

Starting point was `spm_BIDS.m` from [SPM12](https://github.com/spm/spm12) ([documentation](https://en.wikibooks.org/wiki/SPM/BIDS#BIDS_parser_and_queries)) reformatted in a `+bids` package with dependencies to other SPM functions removed.

## Other tools (MATLAB only)
- [dicm2nii](https://github.com/xiangruili/dicm2nii): A DICOM to BIDS converter
- [imtool3D_BIDS](https://github.com/tanguyduval/imtool3D_td): A 3D viewer for BIDS directory
