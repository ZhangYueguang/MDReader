# Contributing to MDReader

Thank you for helping improve MDReader. Changes should preserve its core promise: quiet, accurate Markdown reading and native source editing on macOS.

## Before You Start

- Search existing issues before opening a new one.
- Use an issue to discuss substantial features or architectural changes before implementation.
- Keep pull requests focused on one problem.
- Keep editing behavior compatible with the native macOS document lifecycle.

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
bash scripts/build-dmg.sh --skip-build
bash scripts/verify-dmg.sh release/MDReader-1.1.0.dmg
(cd release && shasum -a 256 -c SHA256SUMS)
```

Running `scripts/build-dmg.sh` without `--skip-build` performs the complete application build before packaging. The generated `release/` directory is intentionally excluded from Git; published binaries belong in GitHub Releases.

## Release Packaging

The application version in `Config/Info.plist`, the package version in `package.json`, and the Git tag must match. Pushing a tag such as `v1.1.0` starts the Release workflow, which builds and verifies the DMG and publishes both `MDReader-1.1.0.dmg` and `SHA256SUMS`.

Public releases must accurately state their signing status. Do not describe a build as Developer ID signed or notarized unless the corresponding Apple verification has succeeded.

## Pull Requests

- Explain the user-facing problem and the chosen solution.
- Include tests for behavior changes and bug fixes.
- Update documentation when requirements or supported syntax change.
- Preserve coordinated document saving, source-encoding behavior, and the renderer's content-security boundaries.
- Keep all source code, documentation, test descriptions, and user-facing copy in English.

By contributing, you agree that your contributions will be licensed under the MIT License.
