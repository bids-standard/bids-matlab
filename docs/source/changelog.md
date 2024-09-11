# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--

## [unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security
-->

## [v0.3.0] - 2024-09-11

### Added

* [ENH] Add zero padding when numbers are passed for indices to `bids.File` or `bids.File.rename` [680](https://github.com/bids-standard/bids-matlab/pull/680) by by [Remi-Gau](https://github.com/Remi-Gau)
* [ENH] remove checks for participants.tsv or samples.tsv in derivatives by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/666
* [ENH] sanitize entities in rename spec by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/679
* [ENH] Added modality retrieval from path by by [nbeliy](https://github.com/nbeliy)  in https://github.com/bids-standard/bids-matlab/pull/656
* [ENH] add zero padding to entity labels / indices when passed as numbers by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/680
* [ENH] add support for BIDS MRS by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/718

### Fixed

* [FIX] Create valid participants and sessions tsv during dataset init [688](https://github.com/bids-standard/bids-matlab/pull/688) by by [Remi-Gau](https://github.com/Remi-Gau)
* [FIX] create valid participants and sessions tsv during dataset init by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/688
* [FIX] handle error for misshaped tsv by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/667
* [FIX] index modality at same level as sessions by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/681
* [FIX] set default empty modality for files with no entities by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/691
* [FIX] ignore 'na' as trial types when creating default models by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/709
* [FIX] Suppress warning when session is taken for modality when going schemaless by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/710
* [FIX] fix validation of F contrasts by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/711
* [FIX] handle rare case where intended for field is empty by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/716

**Full Changelog**: https://github.com/bids-standard/bids-matlab/compare/v0.2.0...v0.3.0

## [v0.2.0]

## What's Changed

Note some changes are missing from these release notes, but should be listed in the pull request that merged the [`dev` branch in the `main` branch](https://github.com/bids-standard/bids-matlab/pull/647).

* [FIX] do not create empty json when copying to derivatives by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/322
* [DOC] add orcid numbers to CITATION.CFF by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/337
* [INFRA] only run update schema on upstream repo by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/343
* [FIX] change download of moae demo dataset by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/351
* [FIX] Skip missing suffix subgroup by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/365
* [FIX] add test to catch error for invalid entities by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/367
* [FIX] add warning when indexing folder with invalid MATLAB structure name by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/366
* [DOC & ENH] update doc query and allow to query any BIDS entity by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/368
* [REF] Use JSON version of the schema by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/415
* [ENH] add NIRS support by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/433
* [FIX]  query with empty subject should return empty and not fail by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/455
* [FIX] fix spelling with codespell by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/457
* [FIX] make bids.copy strict by default by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/468
* [FIX] add try catch for rare errors on invalid bids datasets by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/471
* [FIX] cleaner handling of missing dependency by by [nbeliy](https://github.com/nbeliy)  in https://github.com/bids-standard/bids-matlab/pull/473
* [FIX] do not index files that start with certain string by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/479
* [FIX] remove byte order mark from tsv file by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/556
* [FIX] handle nan and and datetimes when printing tables by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/605
* [MAINT] change to MIT license by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/653
* [MAINT] Drop `dev` branch by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/654

**Full Changelog**: https://github.com/bids-standard/bids-matlab/compare/v0.1.0...v0.2.0

## [v0.1.0]

* Bids report by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/1
* small fix in a filter that skipped json files when they were in the root folder by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/8
* Readme update: Add converter and viewer by by [tanguyduval](https://github.com/tanguyduval)  in https://github.com/bids-standard/bids-matlab/pull/13
* [WIP] Unit tests - read metadata by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/10
* Query by by [tanguyduval](https://github.com/tanguyduval)  in https://github.com/bids-standard/bids-matlab/pull/12
* multi file datasets (such as BrainVision) should be represented as a single dataset, not multiple  by by [robertoostenveld](https://github.com/robertoostenveld)  in https://github.com/bids-standard/bids-matlab/pull/14
* Add some extra comments to better explain each function by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/21
* More detailed error messages by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/30
* gitignore: ignore local copy of bids-examples by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/31
* util.tsvread: Make it a recursive call to self by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/33
* util: Support jsonencode/jsondecode as regular functions by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/24
* Include QUERY in the H1 line for query's helptext by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/29
* Make function helptext more concise with a +bids/Contents.m by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/32
* README: Document requirements by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/36
* Handle non-standard-format metadata JSON files by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/37
* Doc: Typo fixes in comments and helptext by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/38
* Refactoring and renaming by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/41
* Create a tsvwrite function by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/40
* Tolerant option for bids.layout by by [tanguyduval](https://github.com/tanguyduval)  in https://github.com/bids-standard/bids-matlab/pull/11
* Fix or suppress M-lint code inspection warnings by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/57
* Move +bids/private stuff to +bids/+internal? by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/25
* [INFRA] Use Ubuntu Focal 20.04 in Travis tests by by [gllmflndn](https://github.com/gllmflndn)  in https://github.com/bids-standard/bids-matlab/pull/72
* [FIX] Filter subjects and sessions when querying modalities (issue [65](https://github.com/bids-standard/bids-matlab/pull/65)) by by [gllmflndn](https://github.com/gllmflndn)  in https://github.com/bids-standard/bids-matlab/pull/71
* [FIX] fix writing nan issues when dealing with arrays by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/74
* Add Brainstorm to README by by [cMadan](https://github.com/cMadan)  in https://github.com/bids-standard/bids-matlab/pull/62
* add code of conduct from bids-specs by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/80
* [INFRA] set up miss_hit linter config and github action by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/58
* Add tsvwrite to documentation by by [gllmflndn](https://github.com/gllmflndn)  in https://github.com/bids-standard/bids-matlab/pull/85
* miss_hit.cfg: define project_root by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/87
* README: fix MISS_HIT name styling by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/89
* Add .editorconfig? by by [apjanke](https://github.com/apjanke)  in https://github.com/bids-standard/bids-matlab/pull/86
* Skip datasets when labelled as non-conformant by by [gllmflndn](https://github.com/gllmflndn)  in https://github.com/bids-standard/bids-matlab/pull/94
* [DOC] Describe what bids-matlab can and cannot do by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/84
* apply MISS_HIT linter across the board by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/95
* Decision making & contributing by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/81
* [FIX] add "dir" to the list of func entities by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/99
* [INFRA] Customize code suggestions & completions by adding a functionSignatures file by by [mslw](https://github.com/mslw)  in https://github.com/bids-standard/bids-matlab/pull/42
* docs: add mslw as a contributor by by [allcontributors](https://github.com/allcontributors)  in https://github.com/bids-standard/bids-matlab/pull/106
* [INFRA] conversion BIDS schema to json by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/101
* [INFRA] run tests with github action by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/100
* [INFRA] switch to moxunit for tests by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/108
* refactoring and linting by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/109
* [ENH] update schema - changes by create-pull-request action by by [github-actions](https://github.com/github-actions)  in https://github.com/bids-standard/bids-matlab/pull/119
* Feature #asl bids by by [HenkMutsaerts](https://github.com/HenkMutsaerts)  in https://github.com/bids-standard/bids-matlab/pull/127
* [MISC] refactor and add tests for layout asl by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/132
* docs: add HenkMutsaerts as a contributor by by [allcontributors](https://github.com/allcontributors)  in https://github.com/bids-standard/bids-matlab/pull/135
* [ENH] implement bids-schema - part 1 by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/124
* [ENH] schemaless layout indexes json files by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/147
* [ENH] add possibility to query for (and filter queries with) extensions by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/150
* [ENH] improve management of "intended_for" by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/151
* [ENH] update fieldname m0 scan estimate by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/149
* Bug in file_utils by by [nbeliy](https://github.com/nbeliy)  in https://github.com/bids-standard/bids-matlab/pull/166
* [HOT FIX] fixed bug in file_utils by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/168
* [HOT FIX] implement hot fix for tsv write by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/170
* [ENH] schema-less indexing collects files prefix that can be returned / filtered by query by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/154
* [HOT FIX] implement hot fix for tsv write by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/173
* [INFRA] BIDS schema update by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/180
* [INFRA] remove obsolete schema files by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/181
* [FIX] lower priority to use SPM function to deal with json files by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/178
* [DOC] update instructions to run the tests by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/183
* [ENH] index sessions.tsv and scans.tsv by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/182
* [FIX] default pattern of get_metada expects suffixes to be preceded by underscore by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/179
* [FIX] default pattern of get_metada expects suffixes to be preceded by underscore by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/189
* [FIX] ensures that metadata file have the same prefix as the queried file by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/195
* [DOC] update install isntructions in README by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/197
* [INFRA] update miss_hit version and add pre-commit hook by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/198
* [WIP] Function to copy derivatives by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/171
* [FIX] fix and refactor report by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/206
* [Fix] fix issues when parsing prefix and ordering entities after parsing filename by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/210
* [FIX] fix bugs in copy to derivatives by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/207
* [FIX] return empty output of append to layout when failing to parse using schema by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/212
* [INFRA] remove unnecessary tsv files in test folder by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/216
* [INFRA] remove unnecessary tsv files in test folder by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/217
* [INFRA] add copyright checks from miss_hit by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/218
* [ENH] implement input parser for copy_to_derivatives by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/221
* [ENH] copy participants, sessions, scans TSV to derivatives by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/222
* [ENH] add basic function to generate and update dataset_description by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/184
* [ENH] add basic filename, path and derivatives JSON creation by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/203
* [ENH] add basic capabilities to initialize a dataset by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/224
* [REF] refactor schema functions into a class by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/225
* [INFRA] fix CI by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/227
* [DOC] set up sphinx and read the docs  by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/229
* Refactor report and update doc, jupyter notebook, binder by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/230
* Update binder and jupyter notebooks by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/231
* Refactoring by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/232
* [FIX] files with missing required entities, unknown entities or extensions are skipped when using layout with schema by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/237
* Refactor error and warning handling by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/239
* [ENH] Index nested derivatives by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/240
* [FIX] copy to derivatives for windows by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/242
* [FIX] typos in filename function by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/246
* [FIX] fix bug in create filename when entities is missing by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/247
* Speed up dependencies indexing by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/243
* Dev - jsonwrite by default by by [CPernet](https://github.com/CPernet)  in https://github.com/bids-standard/bids-matlab/pull/249
* docs: add CPernet as a contributor for code, ideas by by [allcontributors](https://github.com/allcontributors)  in https://github.com/bids-standard/bids-matlab/pull/251
* [FIX] enforce valid fieldnames in schema content and skip schema metadata loading by default by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/256
* [FIX] update bids init related functions to more BIDS compliant default output by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/257
* [FIX] allows filtering with entities for query than "data" by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/259
* [ENH] Index tsv and json files in root folder  by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/261
* add error message to parse_filename by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/264
* Improve bids.init by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/263
* [DOC] add matlab exchange badge in README by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/270
* [DOC] General update of the sphinx doc by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/269
* [ENH] improves constructors for schema and dataset description by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/271
* Added treatment of bids-incomatible files in dataset by by [nbeliy](https://github.com/nbeliy)  in https://github.com/bids-standard/bids-matlab/pull/268
* [ENH] refactor create_filename and create_path into a bids.File class by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/273
* [ENH] update Schema class to new schema structure  by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/285
* [INFRA] implement matlab github action by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/201
* [INFRA] silence codecov by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/290
* [ENH] Improve bids.query by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/286
* [ENH] fix and improve bids.report by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/280
* [TEST] add test for copying to derivatives with an exclude filter by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/292
* Improvement of File.m interface by by [nbeliy](https://github.com/nbeliy)  in https://github.com/bids-standard/bids-matlab/pull/289
* [FIX] fix the regex when querying subjects by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/295
* docs: add ChristophePhillips as a contributor for ideas by by [allcontributors](https://github.com/allcontributors)  in https://github.com/bids-standard/bids-matlab/pull/303
* [INFRA] add CITATION.cff file by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/284
* [ENH] update and standardize API by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/305
* [ENH] do not index json with bids.layout by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/307
* [ENH] make bids.query return list of availables labels for some common derivative entities by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/308
* [ENH] validate entity keys provided when using BIDS schema to create filenames by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/309
* [INFRA] test for matlab octave difference by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/310
* [INFRA] fix failing tests on windows by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/311
* [ENH] add support for microscoy by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/315
* [REL] rc0.1.0 by by [Remi-Gau](https://github.com/Remi-Gau)  in https://github.com/bids-standard/bids-matlab/pull/287

## New Contributors
* by [tanguyduval](https://github.com/tanguyduval)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/13
* by [robertoostenveld](https://github.com/robertoostenveld)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/14
* by [apjanke](https://github.com/apjanke)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/30
* by [allcontributors](https://github.com/allcontributors)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/52
* by [gllmflndn](https://github.com/gllmflndn)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/72
* by [cMadan](https://github.com/cMadan)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/62
* by [mslw](https://github.com/mslw)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/42
* by [github-actions](https://github.com/github-actions)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/110
* by [HenkMutsaerts](https://github.com/HenkMutsaerts)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/127
* by [nbeliy](https://github.com/nbeliy)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/166
* by [CPernet](https://github.com/CPernet)  made their first contribution in https://github.com/bids-standard/bids-matlab/pull/249

**Full Changelog**: https://github.com/bids-standard/bids-matlab/commits/v0.1.0
