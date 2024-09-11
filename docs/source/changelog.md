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

* [ENH] Add zero padding when numbers are passed for indices to `bids.File` or `bids.File.rename` [680](https://github.com/bids-standard/bids-matlab/pull/680) by [Remi-Gau](https://github.com/Remi-Gau)
* [ENH] remove checks for participants.tsv or samples.tsv in derivatives by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/666
* [ENH] sanitize entities in rename spec by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/679
* [ENH] Added modality retrieval from path by [nbeliy](https://github.com/nbeliy) in https://github.com/bids-standard/bids-matlab/pull/656
* [ENH] add zero padding to entity labels / indices when passed as numbers by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/680
* [ENH] add support for BIDS MRS by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/718

### Fixed

* [FIX] Create valid participants and sessions tsv during dataset init [688](https://github.com/bids-standard/bids-matlab/pull/688) by [Remi-Gau](https://github.com/Remi-Gau)
* [FIX] create valid participants and sessions tsv during dataset init by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/688
* [FIX] handle error for misshaped tsv by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/667
* [FIX] index modality at same level as sessions by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/681
* [FIX] set default empty modality for files with no entities by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/691
* [FIX] ignore 'na' as trial types when creating default models by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/709
* [FIX] Suppress warning when session is taken for modality when going schemaless by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/710
* [FIX] fix validation of F contrasts by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/711
* [FIX] handle rare case where intended for field is empty by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/716

**Full Changelog**: https://github.com/bids-standard/bids-matlab/compare/v0.2.0...v0.3.0

## [v0.2.0]

## What's Changed

Note some changes are missing from these release notes, but should be listed in the pull request that merged the [`dev` branch in the `main` branch](https://github.com/bids-standard/bids-matlab/pull/647).

* [FIX] do not create empty json when copying to derivatives by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/322
* [DOC] add orcid numbers to CITATION.CFF by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/337
* [INFRA] only run update schema on upstream repo by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/343
* [FIX] change download of moae demo dataset by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/351
* [FIX] Skip missing suffix subgroup by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/365
* [FIX] add test to catch error for invalid entities by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/367
* [FIX] add warning when indexing folder with invalid MATLAB structure name by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/366
* [DOC & ENH] update doc query and allow to query any BIDS entity by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/368
* [REF] Use JSON version of the schema by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/415
* [ENH] add NIRS support by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/433
* [FIX] query with empty subject should return empty and not fail by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/455
* [FIX] fix spelling with codespell by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/457
* [FIX] make bids.copy strict by default by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/468
* [FIX] add try catch for rare errors on invalid bids datasets by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/471
* [FIX] cleaner handling of missing dependency by [nbeliy](https://github.com/nbeliy) in https://github.com/bids-standard/bids-matlab/pull/473
* [FIX] do not index files that start with certain string by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/479
* [FIX] remove byte order mark from tsv file by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/556
* [FIX] handle nan and and datetimes when printing tables by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/605
* [MAINT] change to MIT license by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/653
* [MAINT] Drop `dev` branch by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/654

**Full Changelog**: https://github.com/bids-standard/bids-matlab/compare/v0.1.0...v0.2.0

## [v0.1.0]

* Bids report by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/1
* small fix in a filter that skipped json files when they were in the root folder by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/8
* Readme update: Add converter and viewer by [tanguyduval](https://github.com/tanguyduval) in https://github.com/bids-standard/bids-matlab/pull/13
* [WIP] Unit tests - read metadata by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/10
* Query by [tanguyduval](https://github.com/tanguyduval) in https://github.com/bids-standard/bids-matlab/pull/12
* multi file datasets (such as BrainVision) should be represented as a single dataset, not multiple by [robertoostenveld](https://github.com/robertoostenveld) in https://github.com/bids-standard/bids-matlab/pull/14
* Add some extra comments to better explain each function by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/21
* More detailed error messages by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/30
* gitignore: ignore local copy of bids-examples by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/31
* util.tsvread: Make it a recursive call to self by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/33
* util: Support jsonencode/jsondecode as regular functions by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/24
* Include QUERY in the H1 line for query's helptext by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/29
* Make function helptext more concise with a +bids/Contents.m by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/32
* README: Document requirements by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/36
* Handle non-standard-format metadata JSON files by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/37
* Doc: Typo fixes in comments and helptext by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/38
* Refactoring and renaming by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/41
* Create a tsvwrite function by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/40
* Tolerant option for bids.layout by [tanguyduval](https://github.com/tanguyduval) in https://github.com/bids-standard/bids-matlab/pull/11
* Fix or suppress M-lint code inspection warnings by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/57
* Move +bids/private stuff to +bids/+internal? by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/25
* [INFRA] Use Ubuntu Focal 20.04 in Travis tests by [gllmflndn](https://github.com/gllmflndn) in https://github.com/bids-standard/bids-matlab/pull/72
* [FIX] Filter subjects and sessions when querying modalities (issue [65](https://github.com/bids-standard/bids-matlab/pull/65)) by [gllmflndn](https://github.com/gllmflndn) in https://github.com/bids-standard/bids-matlab/pull/71
* [FIX] fix writing nan issues when dealing with arrays by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/74
* Add Brainstorm to README by [cMadan](https://github.com/cMadan) in https://github.com/bids-standard/bids-matlab/pull/62
* add code of conduct from bids-specs by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/80
* [INFRA] set up miss_hit linter config and github action by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/58
* Add tsvwrite to documentation by [gllmflndn](https://github.com/gllmflndn) in https://github.com/bids-standard/bids-matlab/pull/85
* miss_hit.cfg: define project_root by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/87
* README: fix MISS_HIT name styling by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/89
* Add .editorconfig? by [apjanke](https://github.com/apjanke) in https://github.com/bids-standard/bids-matlab/pull/86
* Skip datasets when labelled as non-conformant by [gllmflndn](https://github.com/gllmflndn) in https://github.com/bids-standard/bids-matlab/pull/94
* [DOC] Describe what bids-matlab can and cannot do by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/84
* apply MISS_HIT linter across the board by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/95
* Decision making & contributing by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/81
* [FIX] add "dir" to the list of func entities by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/99
* [INFRA] Customize code suggestions & completions by adding a functionSignatures file by [mslw](https://github.com/mslw) in https://github.com/bids-standard/bids-matlab/pull/42
* [INFRA] conversion BIDS schema to json by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/101
* [INFRA] run tests with github action by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/100
* [INFRA] switch to moxunit for tests by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/108
* refactoring and linting by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/109
* [ENH] update schema in https://github.com/bids-standard/bids-matlab/pull/119
* Feature #asl bids by [HenkMutsaerts](https://github.com/HenkMutsaerts) in https://github.com/bids-standard/bids-matlab/pull/127
* [MISC] refactor and add tests for layout asl by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/132
* [ENH] implement bids-schema - part 1 by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/124
* [ENH] schemaless layout indexes json files by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/147
* [ENH] add possibility to query for (and filter queries with) extensions by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/150
* [ENH] improve management of "intended_for" by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/151
* [ENH] update fieldname m0 scan estimate by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/149
* Bug in file_utils by [nbeliy](https://github.com/nbeliy) in https://github.com/bids-standard/bids-matlab/pull/166
* [HOT FIX] fixed bug in file_utils by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/168
* [HOT FIX] implement hot fix for tsv write by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/170
* [ENH] schema-less indexing collects files prefix that can be returned / filtered by query by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/154
* [HOT FIX] implement hot fix for tsv write by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/173
* [INFRA] BIDS schema update by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/180
* [INFRA] remove obsolete schema files by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/181
* [FIX] lower priority to use SPM function to deal with json files by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/178
* [DOC] update instructions to run the tests by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/183
* [ENH] index sessions.tsv and scans.tsv by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/182
* [FIX] default pattern of get_metada expects suffixes to be preceded by underscore by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/179
* [FIX] default pattern of get_metada expects suffixes to be preceded by underscore by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/189
* [FIX] ensures that metadata file have the same prefix as the queried file by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/195
* [DOC] update install isntructions in README by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/197
* [INFRA] update miss_hit version and add pre-commit hook by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/198
* [WIP] Function to copy derivatives by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/171
* [FIX] fix and refactor report by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/206
* [Fix] fix issues when parsing prefix and ordering entities after parsing filename by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/210
* [FIX] fix bugs in copy to derivatives by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/207
* [FIX] return empty output of append to layout when failing to parse using schema by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/212
* [INFRA] remove unnecessary tsv files in test folder by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/216
* [INFRA] remove unnecessary tsv files in test folder by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/217
* [INFRA] add copyright checks from miss_hit by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/218
* [ENH] implement input parser for copy_to_derivatives by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/221
* [ENH] copy participants, sessions, scans TSV to derivatives by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/222
* [ENH] add basic function to generate and update dataset_description by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/184
* [ENH] add basic filename, path and derivatives JSON creation by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/203
* [ENH] add basic capabilities to initialize a dataset by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/224
* [REF] refactor schema functions into a class by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/225
* [INFRA] fix CI by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/227
* [DOC] set up sphinx and read the docs by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/229
* Refactor report and update doc, jupyter notebook, binder by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/230
* Update binder and jupyter notebooks by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/231
* Refactoring by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/232
* [FIX] files with missing required entities, unknown entities or extensions are skipped when using layout with schema by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/237
* Refactor error and warning handling by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/239
* [ENH] Index nested derivatives by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/240
* [FIX] copy to derivatives for windows by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/242
* [FIX] typos in filename function by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/246
* [FIX] fix bug in create filename when entities is missing by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/247
* Speed up dependencies indexing by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/243
* Dev - jsonwrite by default by [CPernet](https://github.com/CPernet) in https://github.com/bids-standard/bids-matlab/pull/249
* [FIX] enforce valid fieldnames in schema content and skip schema metadata loading by default by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/256
* [FIX] update bids init related functions to more BIDS compliant default output by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/257
* [FIX] allows filtering with entities for query than "data" by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/259
* [ENH] Index tsv and json files in root folder by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/261
* add error message to parse_filename by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/264
* Improve bids.init by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/263
* [DOC] add matlab exchange badge in README by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/270
* [DOC] General update of the sphinx doc by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/269
* [ENH] improves constructors for schema and dataset description by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/271
* Added treatment of bids-incomatible files in dataset by [nbeliy](https://github.com/nbeliy) in https://github.com/bids-standard/bids-matlab/pull/268
* [ENH] refactor create_filename and create_path into a bids.File class by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/273
* [ENH] update Schema class to new schema structure by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/285
* [INFRA] implement matlab github action by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/201
* [INFRA] silence codecov by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/290
* [ENH] Improve bids.query by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/286
* [ENH] fix and improve bids.report by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/280
* [TEST] add test for copying to derivatives with an exclude filter by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/292
* Improvement of File.m interface by [nbeliy](https://github.com/nbeliy) in https://github.com/bids-standard/bids-matlab/pull/289
* [FIX] fix the regex when querying subjects by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/295
* [INFRA] add CITATION.cff file by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/284
* [ENH] update and standardize API by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/305
* [ENH] do not index json with bids.layout by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/307
* [ENH] make bids.query return list of availables labels for some common derivative entities by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/308
* [ENH] validate entity keys provided when using BIDS schema to create filenames by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/309
* [INFRA] test for matlab octave difference by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/310
* [INFRA] fix failing tests on windows by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/311
* [ENH] add support for microscoy by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/315
* [REL] rc0.1.0 by [Remi-Gau](https://github.com/Remi-Gau) in https://github.com/bids-standard/bids-matlab/pull/287

## New Contributors
* by [tanguyduval](https://github.com/tanguyduval) made their first contribution in https://github.com/bids-standard/bids-matlab/pull/13
* by [robertoostenveld](https://github.com/robertoostenveld) made their first contribution in https://github.com/bids-standard/bids-matlab/pull/14
* by [apjanke](https://github.com/apjanke) made their first contribution in https://github.com/bids-standard/bids-matlab/pull/30
* by [gllmflndn](https://github.com/gllmflndn) made their first contribution in https://github.com/bids-standard/bids-matlab/pull/72
* by [cMadan](https://github.com/cMadan) made their first contribution in https://github.com/bids-standard/bids-matlab/pull/62
* by [mslw](https://github.com/mslw) made their first contribution in https://github.com/bids-standard/bids-matlab/pull/42
* by [HenkMutsaerts](https://github.com/HenkMutsaerts) made their first contribution in https://github.com/bids-standard/bids-matlab/pull/127
* by [nbeliy](https://github.com/nbeliy) made their first contribution in https://github.com/bids-standard/bids-matlab/pull/166
* by [CPernet](https://github.com/CPernet) made their first contribution in https://github.com/bids-standard/bids-matlab/pull/249

**Full Changelog**: https://github.com/bids-standard/bids-matlab/commits/v0.1.0
