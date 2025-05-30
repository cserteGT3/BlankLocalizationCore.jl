# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project tries to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Types of changes:

- Added
- Changed
- Deprecated
- Removed
- Fixed
- Security

## [Unreleased]

## [2.4.1] - 2025-05-22

Release is only needed for triggering Zenodo for the JuliaCon paper.

### Added

- zenodo archive

## [2.4.0] - 2025-05-22

### Added

- changelog file
- new, simpler 2D example (in docs and Readme too)
- enabled docs preview on PRs (link is `https://csertegt3.github.io/BlankLocalizationCore.jl/previews/PR<num>/`)

### Changed

- CI is updated to the latest version (generated by PkgTemplates)
- code is tested against: julia version 1.10 (LTS), 1.11 (latest) and nightly

### Fixed

- made the installation instructions clear in the examples and Readme
- fixed the visualizatio code in example
- minimum allowance calculation in result evaluation when there's no axial or radial allowance
