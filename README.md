<p align="center">
  <img src="Assets/MDReaderIcon.png" width="144" height="144" alt="MDReader app icon">
</p>

<h1 align="center">MDReader</h1>

<p align="center">
  A calm, read-only Markdown reader for macOS with refined typography and reliable math rendering.
</p>

<p align="center">
  <a href="https://github.com/ZhangYueguang/MDReader/actions/workflows/ci.yml"><img src="https://github.com/ZhangYueguang/MDReader/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-315d71" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-315d71" alt="macOS 14 or later">
  <img src="https://img.shields.io/badge/Swift-6.2-f05138" alt="Swift 6.2">
</p>

MDReader focuses on one job: presenting local Markdown files accurately and beautifully. It never edits the source document. Articles, technical notes, code, tables, images, footnotes, and mathematical notation are rendered in a distraction-free native macOS window.

## Highlights

- CommonMark and GitHub Flavored Markdown, including tables, task lists, strikethrough, autolinks, and footnotes.
- Inline and display math through bundled MathJax, with support for TeX and MathML.
- Syntax highlighting for fenced code blocks.
- YAML front matter rendered as quiet document metadata.
- Local relative images and remote images.
- UTF-8, UTF-16, and GB18030/GBK text decoding.
- One independent window per document.
- A fluid reading column that grows with the window while preserving comfortable line length.
- Light and warm-charcoal dark appearances that follow macOS automatically.
- Fully bundled rendering assets for offline text, code, local images, and math.

## Requirements

- macOS 14 or later
- Swift 6.2 or later
- Node.js 24

## Build from Source

```bash
git clone https://github.com/ZhangYueguang/MDReader.git
cd MDReader
bash scripts/build-app.sh
open dist/MDReader.app
```

The application is created at `dist/MDReader.app`. Local builds use ad hoc code signing and are not notarized with an Apple Developer ID.

## Open Markdown Files

- Choose **Open With → MDReader** in Finder.
- Drag a `.md` or `.markdown` file onto the application icon or an existing reader window.
- Use **File → Open** or press `⌘O` in MDReader.

To open the bundled showcase document:

```bash
open -a dist/MDReader.app Tests/Fixtures/Showcase.md
```

## Architecture

MDReader uses a SwiftUI document-based shell and a tightly controlled `WKWebView` rendering surface.

1. Swift reads the source file without exposing write operations and detects its text encoding.
2. A bundled unified/remark pipeline parses Markdown, applies GFM extensions, and sanitizes embedded HTML.
3. Highlight.js-compatible output styles code blocks.
4. Bundled MathJax typesets TeX and MathML after the Markdown structure is ready.
5. Custom URL schemes expose only packaged resources and images inside the document directory.

External links open in the system browser. Executable and unknown URL schemes are blocked.

## Development

Run the test suites:

```bash
npm ci
npm test
swift run MDReaderTests
```

Build the web renderer and release executable:

```bash
npm run build:web
swift build -c release --product MDReader
```

Run an application smoke test:

```bash
bash scripts/run-smoke-test.sh Tests/Fixtures/Showcase.md
```

## Current Scope

MDReader intentionally does not provide editing, folder navigation, document outlines, search, tabs, automatic file refresh, Mermaid rendering, automatic updates, or notarized binary releases yet.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

MDReader is available under the [MIT License](LICENSE).
