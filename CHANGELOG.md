# Changelog

## [1.2.0] - 2024-04-11

### Added
- New method `deleteFilesFromICloud` for deleting files from iCloud
- New error type `fileNotFound` for cases when specified file is not found in iCloud
- Support for all three async patterns (completion handler, async/await with throws, async/await with Result) for the new method

### Changed
- Updated documentation in README.md with examples for the new method
- Updated package version in Package.swift to 1.2.0 