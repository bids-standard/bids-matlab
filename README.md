## BIDS-MATLAB

This repository aims at centralising MATLAB/Octave tools to interact with datasets conforming to the BIDS (Brain Imaging Data Structure) format.

For more information about BIDS, visit https://bids.neuroimaging.io/.

See also [PyBIDS](https://github.com/bids-standard/pybids) for Python and the [BIDS Starter Kit](https://github.com/bids-standard/bids-starter-kit).

Starting point is `spm_BIDS.m` from [SPM12](https://github.com/spm/spm12) ([documentation](https://en.wikibooks.org/wiki/SPM/BIDS#BIDS_parser_and_queries)). It currently relies on a number of SPM functions: `spm_select.m`, `spm_jsonread.m`, `spm_load.m`, `spm_file.m`, `spm_existfile.m`, but it should be feasible to make this function standalone if preferable.
