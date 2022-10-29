<!-- markdown-link-check-disable -->

<!-- .. only:: html -->

[![tests_matlab](https://github.com/bids-standard/bids-matlab/actions/workflows/run_tests_matlab.yml/badge.svg)](https://github.com/bids-standard/bids-matlab/actions/workflows/run_tests_matlab.yml)
[![tests_octave](https://github.com/bids-standard/bids-matlab/actions/workflows/run_tests_octave.yml/badge.svg)](https://github.com/bids-standard/bids-matlab/actions/workflows/run_tests_octave.yml)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/bids-standard/bids-matlab/dev?urlpath=demos)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/bids-standard/bids-matlab/dev.svg)](https://results.pre-commit.ci/latest/github/bids-standard/bids-matlab/dev)
[![miss hit](https://img.shields.io/badge/code%20style-miss_hit-000000.svg)](https://misshit.org/)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/bids-standard/bids-matlab/dev?urlpath=demos)
[![View bids-matlab on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://nl.mathworks.com/matlabcentral/fileexchange/93740-bids-matlab)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5910584.svg)](https://doi.org/10.5281/zenodo.5910584)
[![All Contributors](https://img.shields.io/badge/all_contributors-13-orange.svg?style=flat-square)](#contributors-)

<!-- markdown-link-check-enable -->

- [BIDS for MATLAB / Octave](#bids-for-matlab--octave)
  - [Installation](#installation)
    - [Get the latest features](#get-the-latest-features)
  - [Features](#features)
    - [What this toolbox can do](#what-this-toolbox-can-do)
    - [What this toolbox cannot do... yet](#what-this-toolbox-cannot-do-yet)
    - [What will this toolbox most likely never do](#what-will-this-toolbox-most-likely-never-do)
  - [Usage](#usage)
  - [Demos](#demos)
  - [Requirements](#requirements)
    - [Reading and writing JSON files](#reading-and-writing-json-files)
  - [Implementation](#implementation)
  - [Get in touch](#get-in-touch)
  - [Other tools (MATLAB only)](#other-tools-matlab-only)
  - [Contributing](#contributing)

# BIDS for MATLAB / Octave

This repository aims at centralising MATLAB/Octave tools to interact with
BIDS (Brain Imaging Data Structure) datasets.

For more information about BIDS, visit https://bids.neuroimaging.io/.

See also [PyBIDS](https://github.com/bids-standard/pybids) for Python and the
[BIDS Starter Kit](https://github.com/bids-standard/bids-starter-kit).

## Installation

Download, unzip this repository and add its content to the MATLAB/Octave path.

```Matlab
unzip('https://github.com/bids-standard/bids-matlab/archive/master.zip');
addpath('bids-matlab-master');
```

Or clone it with git:

```bash
git clone https://github.com/bids-standard/bids-matlab.git
```

and then add it to your MATLAB/Octave path.

```Matlab
addpath('bids-matlab');
```

### Get the latest features

The latest features of bids-matlab that are in development are in our `dev`
branch.

To access them you can either download the `dev` branch from there:
https://github.com/bids-standard/bids-matlab/tree/dev

Or clone it:

```bash
git clone --branch dev https://github.com/bids-standard/bids-matlab.git
```

Or you can check it out the `dev` branch after the adding this official
bids-matlab repository as a remote.

```
git add remote upstream https://github.com/bids-standard/bids-matlab.git
git checkout upstream/dev
```

## Features

### What this toolbox can do

- read the layout of a BIDS dataset (see `bids.layout`),

- perform queries on that layout to get information about the subjects,
  sessions, runs, modalities, metadata... contained within that dataset (see
  `bids.query`),

- parse the layout of "BIDS-derivative compatible" datasets (like those
  generated by fMRIprep),

- create BIDS compatible filenames or folder structures for raw or derivatives
  datasets (`bids.File`, `bids.util.mkdir`,
  `bids.dataset_description`),

- do basic copying of files to help initialize a derivative dataset
  to start a new analysis (`bids.copy_to_derivative`),

- generate a human readable report of the content of BIDS data set containing
  anatomical MRI, functional MRI, diffusion weighted imaging, field map data
  (see `bids.report`)

- create summary figures listing the number of files for each subject / session and
  and imaging modality (see `bids.diagnostic`)

- read and write JSON files (see `bids.util.jsondecode` and
  `bids.util.jsonwrite`) provided that the right
  [dependencies](#reading-and-writing-json-files) are installed,

- read and write TSV files (see `bids.util.tsvread` and `bids.util.tsvwrite`)

- access and query the [BIDS schema](https://bids-specification.readthedocs.io/en/latest/schema.json) (`bids.schema`)

- access, query and create basic transformations for the [BIDS statistical model](https://bids-standard.github.io/stats-models/) (`bids.Model` and `bids.transformers`)

The behavior of this toolbox assumes that it is interacting with a valid BIDS
dataset that should have been validated using
[BIDS-validator](https://bids-standard.github.io/bids-validator/). If the
Node.js version of the validator is
[installed on your computer](https://github.com/bids-standard/bids-validator#quickstart),
you can call it from the matlab prompt using `bids.validate`. Just be aware that
any unvalidated components may produce undefined behavior. Although, if you're
BIDS-y enough, the behavior may be predictable.

### What this toolbox cannot do... yet

- generate human readable reports of the content of BIDS data with EEG, MEG,
  iEEG, physio and events data,

### What will this toolbox most likely never do

- act as a Matlab / Octave based BIDS-validator
- act as a BIDS converter
- implement reading / writing capabilities for the different modality-specific
  data format that exist in BIDS (`.nii`, `.eeg`, `.ds`, `.fif`...)

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

## Demos

There are demos and tutorials showing some of the features in the `demos` folder.

## Requirements

BIDS-MATLAB works with:

- Octave 5.2.0 or newer
- MATLAB R2014a or newer

We aim for compatibility with the latest stable release of Octave at any time.
Compatibility can sometimes also be achieved with older versions of Octave but
this is not guaranteed.

### Reading and writing JSON files

Make sure to be familiar with the [JSON 101](https://bids-standard.github.io/stats-models/json_101.html).

Note some of the perks of working with JSON files described
on [the BIDS starterkit](https://bids-standard.github.io/bids-starter-kit/folders_and_files/metadata.html#interoperability-issues).

For BIDS-MATLAB, if you are using MATLAB R2016b or newer, nothing else needs to be installed.

If you are using MATLAB R2016a or older, or using Octave, you need to install a
supported JSON library for your MATLAB or Octave. This can be any of:

- [JSONio](https://github.com/gllmflndn/JSONio) for MATLAB or Octave
- [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)

## Implementation

Starting point was `spm_BIDS.m` from [SPM12](https://github.com/spm/spm12)
([documentation](https://en.wikibooks.org/wiki/SPM/BIDS#BIDS_parser_and_queries))
reformatted in a `+bids` package with dependencies to other SPM functions
removed.

## Get in touch

To contact us:

- open an [issue](https://github.com/bids-standard/bids-matlab/issues/new/choose)
- join our chat on the
[BIDS-MATLAB channel](https://mattermost.brainhack.org/brainhack/channels/bids-matlab)
on the brainhack mattermost
- join our [google group](https://groups.google.com/g/bids-matlab).

## Other tools (MATLAB only)

- [dicm2nii](https://github.com/xiangruili/dicm2nii): A DICOM to BIDS
  converter
- [imtool3D_BIDS](https://github.com/tanguyduval/imtool3D_td): A 3D viewer for
  BIDS directory
- [Brainstorm](https://github.com/brainstorm-tools/brainstorm3): Comprehensive
  brain analysis toolbox (includes BIDS
  [import and export](https://neuroimage.usc.edu/brainstorm/ExportBids) and
  different examples dealing with BIDS datasets (e.g.
  [group analysis from a MEG visual dataset](https://neuroimage.usc.edu/brainstorm/Tutorials/VisualGroup),
  [resting state analysis from OMEGA datasets](https://neuroimage.usc.edu/brainstorm/Tutorials/RestingOmega#BIDS_specifications)
  )

## Contributing

If you want to contribute make sure to check our [contributing guidelines](CONTRIBUTING.md)
and our [code of conduct](CODE_OF_CONDUCT.md).

Thanks goes to these wonderful people
([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center"><a href="https://github.com/gllmflndn"><img src="https://avatars0.githubusercontent.com/u/5950855?v=4?s=100" width="100px;" alt="Guillaume"/><br /><sub><b>Guillaume</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=gllmflndn" title="Code">💻</a> <a href="#design-gllmflndn" title="Design">🎨</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=gllmflndn" title="Documentation">📖</a> <a href="#example-gllmflndn" title="Examples">💡</a> <a href="#ideas-gllmflndn" title="Ideas, Planning, & Feedback">🤔</a> <a href="#infra-gllmflndn" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#maintenance-gllmflndn" title="Maintenance">🚧</a> <a href="#question-gllmflndn" title="Answering Questions">💬</a> <a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Agllmflndn" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=gllmflndn" title="Tests">⚠️</a></td>
      <td align="center"><a href="https://remi-gau.github.io/"><img src="https://avatars3.githubusercontent.com/u/6961185?v=4?s=100" width="100px;" alt="Remi Gau"/><br /><sub><b>Remi Gau</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=Remi-Gau" title="Code">💻</a> <a href="#design-Remi-Gau" title="Design">🎨</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=Remi-Gau" title="Documentation">📖</a> <a href="#example-Remi-Gau" title="Examples">💡</a> <a href="#ideas-Remi-Gau" title="Ideas, Planning, & Feedback">🤔</a> <a href="#maintenance-Remi-Gau" title="Maintenance">🚧</a> <a href="#question-Remi-Gau" title="Answering Questions">💬</a> <a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3ARemi-Gau" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=Remi-Gau" title="Tests">⚠️</a></td>
      <td align="center"><a href="http://apjanke.net"><img src="https://avatars2.githubusercontent.com/u/2618447?v=4?s=100" width="100px;" alt="Andrew Janke"/><br /><sub><b>Andrew Janke</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=apjanke" title="Code">💻</a> <a href="#design-apjanke" title="Design">🎨</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=apjanke" title="Documentation">📖</a> <a href="#ideas-apjanke" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Aapjanke" title="Reviewed Pull Requests">👀</a> <a href="#infra-apjanke" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
      <td align="center"><a href="https://github.com/tanguyduval"><img src="https://avatars1.githubusercontent.com/u/7785316?v=4?s=100" width="100px;" alt="tanguyduval"/><br /><sub><b>tanguyduval</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=tanguyduval" title="Code">💻</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=tanguyduval" title="Documentation">📖</a> <a href="#ideas-tanguyduval" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="https://github.com/robertoostenveld"><img src="https://avatars1.githubusercontent.com/u/899043?v=4?s=100" width="100px;" alt="Robert Oostenveld"/><br /><sub><b>Robert Oostenveld</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=robertoostenveld" title="Code">💻</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=robertoostenveld" title="Documentation">📖</a> <a href="#ideas-robertoostenveld" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Arobertoostenveld" title="Reviewed Pull Requests">👀</a></td>
      <td align="center"><a href="http://www.cmadan.com"><img src="https://avatars0.githubusercontent.com/u/6385051?v=4?s=100" width="100px;" alt="Christopher Madan"/><br /><sub><b>Christopher Madan</b></sub></a><br /><a href="#content-cMadan" title="Content">🖋</a></td>
      <td align="center"><a href="http://guiomarniso.com"><img src="https://avatars1.githubusercontent.com/u/4451818?v=4?s=100" width="100px;" alt="Julia Guiomar Niso Galán"/><br /><sub><b>Julia Guiomar Niso Galán</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Aguiomar" title="Reviewed Pull Requests">👀</a></td>
    </tr>
    <tr>
      <td align="center"><a href="https://github.com/mslw"><img src="https://avatars1.githubusercontent.com/u/11985212?v=4?s=100" width="100px;" alt="Michał Szczepanik"/><br /><sub><b>Michał Szczepanik</b></sub></a><br /><a href="#infra-mslw" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#ideas-mslw" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=mslw" title="Code">💻</a></td>
      <td align="center"><a href="http://www.ExploreASL.org"><img src="https://avatars.githubusercontent.com/u/27774254?v=4?s=100" width="100px;" alt="Henk Mutsaerts"/><br /><sub><b>Henk Mutsaerts</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=HenkMutsaerts" title="Code">💻</a> <a href="#ideas-HenkMutsaerts" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="https://github.com/nbeliy"><img src="https://avatars.githubusercontent.com/u/44231332?v=4?s=100" width="100px;" alt="Nikita Beliy"/><br /><sub><b>Nikita Beliy</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=nbeliy" title="Code">💻</a> <a href="#ideas-nbeliy" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Anbeliy" title="Reviewed Pull Requests">👀</a></td>
      <td align="center"><a href="https://profiles.stanford.edu/martin-noergaard"><img src="https://avatars.githubusercontent.com/u/12412821?v=4?s=100" width="100px;" alt="Martin Norgaard"/><br /><sub><b>Martin Norgaard</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/issues?q=author%3Amnoergaard" title="Bug reports">🐛</a> <a href="#ideas-mnoergaard" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="https://cpernet.github.io/"><img src="https://avatars.githubusercontent.com/u/4772878?v=4?s=100" width="100px;" alt="Cyril Pernet"/><br /><sub><b>Cyril Pernet</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=CPernet" title="Code">💻</a> <a href="#ideas-CPernet" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="http://www.giga.uliege.be"><img src="https://avatars.githubusercontent.com/u/2011934?v=4?s=100" width="100px;" alt="Christophe Phillips"/><br /><sub><b>Christophe Phillips</b></sub></a><br /><a href="#ideas-ChristophePhillips" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="https://github.com/CerenB"><img src="https://avatars.githubusercontent.com/u/10451654?v=4?s=100" width="100px;" alt="CerenB"/><br /><sub><b>CerenB</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3ACerenB" title="Reviewed Pull Requests">👀</a></td>
    </tr>
    <tr>
      <td align="center"><a href="http://cpplab.be"><img src="https://avatars.githubusercontent.com/u/38101692?v=4?s=100" width="100px;" alt="marcobarilari"/><br /><sub><b>marcobarilari</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Amarcobarilari" title="Reviewed Pull Requests">👀</a></td>
      <td align="center"><a href="https://github.com/mwmaclean"><img src="https://avatars.githubusercontent.com/u/54547865?v=4?s=100" width="100px;" alt="Michèle MacLean"/><br /><sub><b>Michèle MacLean</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/issues?q=author%3Amwmaclean" title="Bug reports">🐛</a></td>
      <td align="center"><a href="https://github.com/JeanneCaronGuyon"><img src="https://avatars.githubusercontent.com/u/8718798?v=4?s=100" width="100px;" alt="Jeanne Caron-Guyon"/><br /><sub><b>Jeanne Caron-Guyon</b></sub></a><br /><a href="#ideas-JeanneCaronGuyon" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="https://github.com/rotemb9"><img src="https://avatars.githubusercontent.com/u/18393230?v=4?s=100" width="100px;" alt="Rotem Botvinik-Nezer"/><br /><sub><b>Rotem Botvinik-Nezer</b></sub></a><br /><a href="#ideas-rotemb9" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="https://github.com/iqrashahzad14"><img src="https://avatars.githubusercontent.com/u/75671348?v=4?s=100" width="100px;" alt="Iqra Shahzad"/><br /><sub><b>Iqra Shahzad</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Aiqrashahzad14" title="Reviewed Pull Requests">👀</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the
[all-contributors](https://github.com/all-contributors/all-contributors)
specification. Contributions of any kind welcome!
