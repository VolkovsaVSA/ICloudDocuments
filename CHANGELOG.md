# Changelog

## [1.2.1] - 2025-04-13

### Added
- New error type `fileCopyFailed` for better error handling during file copy operations
- Localized error messages for better user experience

### Changed
- Refactored test code to use constants for file names and paths
- Improved code maintainability by reducing string duplication
- Updated documentation in README.md with recent changes and improvements
- Removed Result-based async methods in favor of throws-based async/await pattern for better error handling

## [1.2.0] - 2025-04-11

### Added
- New method `deleteFilesFromICloud` for deleting files from iCloud
- New error type `fileNotFound` for cases when specified file is not found in iCloud
- Support for all three async patterns (completion handler, async/await with throws, async/await with Result) for the new method

### Changed
- Updated documentation in README.md with examples for the new method
- Updated package version in Package.swift to 1.2.0 