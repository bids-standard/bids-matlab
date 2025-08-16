# Maintenance


## Updating the bids-schema

The [schema of the BIDS specification](https://bids.neuroimaging.io/standards/schema/index.html) is available as a JSON file here: https://bids-specification.readthedocs.io/en/latest/schema.json

The latest version can be obtained by running the following command:

```bash
make update_schema
```

A new version of the schema is fetched automatically regularly via continuous integration
(see the [github action](.github/workflows/update_schema.yml)) when pushing to the repo
or opening a pull-request.

## Release protocol

General steps to follow when making a new release.

- [ ] create a dedicated branch for the release candidate
- [ ] update version in `citation.cff`
- [ ] documentation related
  - [ ] ensure the documentation is up to date
  - [ ] make sure the doc builds correctly and fix any error
- [ ] update jupyter books
- [ ] update binder
- [ ] update changelog
  - [ ] change from `[unreleased]` to the version number
  - [ ] remove unused sections (like `security`)
- [ ] run `make release`
- [ ] open a pull request (PR) from this release candidate branch targeting the default branch
- [ ] fix any remaining failing continuous integration (test, markdown and code linting...)
- [ ] merge to default branch
- [ ] create a github tagged release
- [ ] after release
  - [ ] set version in `citation.cff` to dev
  - [ ] update changelog
    - [ ] add an `[unreleased]` section
