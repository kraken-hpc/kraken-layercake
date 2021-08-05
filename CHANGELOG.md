# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2021-08-05
### Changed
- port imageapi module and extension to ImageAPI v0.2.0
### Fixed
- fix vmOff command to libvirt to use DomainDestroy
- fix incorrect command versions

## [0.1.1] - 2021-05-17
### Added
- Added this changelog (`CHANGELOG.md`)
- Added Dockerhub builds for `kraken-layercake` and `kraken-layercake-virt`
### Changed
- `vbox-layer0` example now uses containers/podman to run
- `freebusy` is now included in layer0-base builds by default
### Fixed
- `vbox-layer0` example is now fully functional again (post migration/split)
- Issue where `build-layer0-base.sh` would use the wrong flags to build a newc cpio
- Issue where `kraken-layercake` got built into u-root, even for `kraken-layercake-virt` builds
- Issue where `imageapi` and `kraken-layercake` would get confused on fork
- Issue where `vboxapi` would sometimes try to listen on an interface that didn't exist yet

## [0.1.0] - 2021-04-13
### Added
- Semantic versioning started.  Note: this project has been in dev for some time, but never previously versioned.
### Changed
- Migrate from github.com/hpc/kraken to github.com/kraken-hpc/kraken
- Split-out from the main github.com/kraken-hpc/kraken project
