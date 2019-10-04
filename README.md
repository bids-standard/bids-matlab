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

### Technical representation of the BIDS layout

The way I now see it is as follows

```
BIDS.description  % from dataset_description.json
BIDS.participants % from participants.tsv
BIDS.sessions     % from sessions.tsv, array of Nsubjects x 1
BIDS.subjects     % data for each modailty in each subject*sesssion
BIDS.scans        % from scans.tsv, array of (Nsubjects*Nsessions) x 1
```

In the layout, `sessions` has (conceptually) the same size as `participants` (although differently represented).

In the layout, `scans` has the same size as `subjects`.

I propose to rename `subjects` to `subses`, since it corresponds to subjects _and_ sessions. Every `subses` has the modalities (anat, func, eeg, etc) as structure arrays, where each array corresponds to one data file. For example

```
>> BIDS.subjects(1)
ans =
  struct with fields:

       name: 'sub-01'
       path: '/Users/roboos/tmp/bids-examples/synthetic/sub-01/ses-01'
    session: 'ses-01'
       anat: [1×1 struct]
       func: [8×1 struct]
       fmap: [0×0 struct]
        beh: [0×0 struct]
        dwi: [0×0 struct]
        eeg: [0×0 struct]
        meg: [0×0 struct]
       ieeg: [0×0 struct]
        pet: [0×0 struct]
```

### User interface

Users are not meant to directly interface with the BIDS layout, but rather use the `query` function. In general that works like

```
BIDS.query(layout, 'item') returns a complete list of the specific items
BIDS.query(layout, 'item', ...) allows additional key-val pairs for selection
```

#### Querying for arrays of strings

```
BIDS.query(layout, 'subjects') returns an array of strings like {'01', '02', ...}
BIDS.query(layout, 'sessions') returns an array of strings
BIDS.query(layout, 'modalities') returns an array of strings, like {'eeg', 'anat'}
BIDS.query(layout, 'types') returns an array of strings, like {'eeg', 'T1w', 'T2w'}
BIDS.query(layout, 'tasks') returns an array of strings
BIDS.query(layout, 'runs') returns an array of strings
```

For subjects, sessions and modalities it can come from the directory structure. For tasks and runs it has to come from the `key-value` entities in the file names. The same could also be used for subjects ('sub-xxx') and sessions ('ses-xxx'), which are in the file name, but the modalities are not as key-value pairs in the file name.

I propose that when you specify

```
BIDS.query(layout, 'subjects') returns an array of strings like {'01', '02', ...}
```

it comes from the directory names, and if you specify

```
BIDS.query(layout, 'subs') returns an array of strings like {'01', '02', ...}
```

it comes from the 'key-value' entities in the file names. This can be generalised such that `acqs`, `procs`, `dirs` and any [entity](https://bids-specification.readthedocs.io/en/stable/99-appendices/04-entity-table.html) appended with an `s` can be processed. A general implementation also supports future or custom entities (e.g. from non-merged BEPs).

That design choice result in the general

```
BIDS.query(layout, entity) returns an array of strings
```

where entity is a string with an `s` appended that matches one of the key-value pairs in the file names. The subjects, sessions, modalities and types remain as explicit queries.

#### Querying for data

The following returns a list of _data_ file names. This excludes the files that come along with the data files, such as the electrodes, channels, photos. For multi-file formats, like BrainVision, it returns only one file name per dataset. For directory based formats, like CTF, it returns the directory name.

```
BIDS.query(layout, 'data') returns an array of strings
```

All other queries of metadata should return an array that is the same size as the array of data files.

#### Querying for different types of metadata

The following returns the content of the JSON files that correspond to the data files (see above). In principle it could also return a list of strings with the file names of the JSON files.

```
BIDS.query(layout, 'metadata') returns an array of structures
```

The following returns electrode positions for each data file (see above). In principle it could also return a list of strings with the file names of the TSV files.

```
BIDS.query(layout, 'electrodes') returns an array of structures
```

In the latter, the electrodes might be replicated if multiple runs were done. Also if you have data with EEG and anatomical MRI, and you did not specify a filter on the query, this should return a cell-array with empty cells for the entries corresponding to anatomical data.

This strategy could support the following, where for each type `xxx` the list that is returned corresponds to the (name or content) of the `basename_xxx.ext` that goes with the data file.

```
BIDS.query(layout, 'xxx')
BIDS.query(layout, 'bval')
BIDS.query(layout, 'bvec')
BIDS.query(layout, 'channels')
BIDS.query(layout, 'electrodes')
BIDS.query(layout, 'headshape')
BIDS.query(layout, 'coordsys')
BIDS.query(layout, 'photos')
```

This can be implemented in a generic way, to allow for future sidecar files to be automatically supported.
