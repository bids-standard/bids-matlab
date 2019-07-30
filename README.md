# BIDS for MATLAB / Octave
[![Build Status](https://travis-ci.com/bids-standard/bids-matlab.svg?branch=master)](https://travis-ci.com/bids-standard/bids-matlab)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/bids-standard/bids-matlab/master?filepath=examples/tutorial.ipynb)

This repository aims at centralising MATLAB/Octave tools to interact with datasets conforming to the BIDS (Brain Imaging Data Structure) format.

For more information about BIDS, visit https://bids.neuroimaging.io/.

See also [PyBIDS](https://github.com/bids-standard/pybids) for Python and the [BIDS Starter Kit](https://github.com/bids-standard/bids-starter-kit).

## Implementation

Starting point was `spm_BIDS.m` from [SPM12](https://github.com/spm/spm12) ([documentation](https://en.wikibooks.org/wiki/SPM/BIDS#BIDS_parser_and_queries)) reformatted in a `+bids` package with dependencies to other SPM functions removed.

## Example

```Matlab
BIDS = bids.layout('/home/data/ds000117');
bids.query(BIDS, 'subjects')
```

## Other tools (MATLAB only)
- [dicm2nii](https://github.com/xiangruili/dicm2nii): A dicom to bids converter
- [imtool3D_BIDS](https://github.com/tanguyduval/imtool3D_td): A 3D viewer for BIDS directory
