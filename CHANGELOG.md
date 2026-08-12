# Changelog

All notable changes to MDReader are documented in this file.

## [1.1.0] - 2026-08-12

### Added

- Explicit Read and Edit modes for every Markdown document.
- A native TextKit source editor with syntax highlighting, undo, redo, find, spell checking, and Chinese input-method support.
- A fixed formatting bar for headings, emphasis, links, quotes, code, math, and lists.
- Native macOS autosave and Command-S support.
- Encoding-preserving writes for UTF-8, UTF-16, and GB18030/GBK documents.
- A File menu command for intentional conversion to UTF-8.

### Changed

- Markdown files are now registered as editable documents instead of viewer-only documents.
- Returning to Read mode immediately typesets the current in-memory source.

## [1.0.0] - 2026-08-11

### Added

- A native, read-only macOS Markdown reading experience.
- CommonMark, GitHub Flavored Markdown, footnotes, front matter, and syntax-highlighted code blocks.
- Bundled MathJax rendering for TeX and MathML without an internet connection.
- Local and remote image rendering with constrained local resource access.
- UTF-8, UTF-16, GB18030, and GBK text decoding.
- Fluid reading widths and automatic light and dark appearances.
- A drag-to-Applications DMG with SHA-256 checksums.
- Automated test, build, and GitHub Release workflows.

[1.0.0]: https://github.com/ZhangYueguang/MDReader/releases/tag/v1.0.0
[1.1.0]: https://github.com/ZhangYueguang/MDReader/releases/tag/v1.1.0
