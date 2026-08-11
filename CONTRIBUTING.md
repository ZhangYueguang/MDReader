# Contributing to MDReader

Thank you for helping improve MDReader. Changes should preserve its core promise: quiet, accurate, read-only Markdown presentation on macOS.

## Before You Start

- Search existing issues before opening a new one.
- Use an issue to discuss substantial features or architectural changes before implementation.
- Keep pull requests focused on one problem.
- Do not add editing or file-writing behavior without prior project discussion.

## Development Setup

You need macOS 14 or later, Swift 6.2 or later, and Node.js 24.

```bash
git clone https://github.com/ZhangYueguang/MDReader.git
cd MDReader
npm ci
```

## Validation

Run both test suites before submitting a pull request:

```bash
npm test
swift run MDReaderTests
```

For changes that affect packaging or resources, also run:

```bash
bash scripts/build-app.sh
bash scripts/run-smoke-test.sh Tests/Fixtures/Showcase.md
```

## Pull Requests

- Explain the user-facing problem and the chosen solution.
- Include tests for behavior changes and bug fixes.
- Update documentation when requirements or supported syntax change.
- Preserve read-only file handling and the renderer's content-security boundaries.
- Keep all source code, documentation, test descriptions, and user-facing copy in English.

By contributing, you agree that your contributions will be licensed under the MIT License.
