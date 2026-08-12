<p align="center">
  <img src="Assets/MDReaderIcon.png" width="144" height="144" alt="MDReader app icon">
</p>

<h1 align="center">MDReader</h1>

<p align="center">
  A calm Markdown reader and editor for macOS with refined typography and reliable math rendering.
</p>

<p align="center">
  <a href="https://github.com/ZhangYueguang/MDReader/actions/workflows/ci.yml"><img src="https://github.com/ZhangYueguang/MDReader/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="https://github.com/ZhangYueguang/MDReader/releases/latest"><img src="https://img.shields.io/github/v/release/ZhangYueguang/MDReader?color=315d71" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-315d71" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-315d71" alt="macOS 14 or later">
  <img src="https://img.shields.io/badge/Swift-6.2-f05138" alt="Swift 6.2">
</p>

MDReader presents local Markdown files accurately and beautifully, then lets you edit the source without leaving the document. Articles, technical notes, code, tables, images, footnotes, and mathematical notation stay readable in a distraction-free native macOS window.

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
- Explicit Read and Edit modes in every document window.
- A native source editor with Markdown syntax highlighting, macOS undo and redo, spell checking, and find.
- A compact formatting bar for headings, emphasis, links, quotes, code, math, and lists.
- Native autosave and `⌘S`, with original UTF-8, UTF-16, and GB18030 encodings preserved.

## Download

**[Download MDReader 1.1.0 for macOS (.dmg)](https://github.com/ZhangYueguang/MDReader/releases/latest/download/MDReader-1.1.0.dmg)**

[View release notes and previous versions](https://github.com/ZhangYueguang/MDReader/releases).

The prebuilt application requires macOS 14 or later. You do not need Swift, Node.js, or any other developer tools.

### Install

1. Download `MDReader-1.1.0.dmg` from the latest release.
2. Open the disk image.
3. Drag **MDReader** onto the **Applications** shortcut.
4. Eject the MDReader disk image.

### First Launch

The current release is ad hoc signed and is not notarized with an Apple Developer ID. macOS may therefore prevent a normal first launch even though the published checksum and application signature have been verified by the release workflow.

1. Open the Applications folder in Finder.
2. Control-click **MDReader**, choose **Open**, and then confirm **Open**.
3. If macOS still blocks the application, try opening it once, then go to **System Settings → Privacy & Security**, scroll down, and choose **Open Anyway**.

Only override macOS security when you downloaded MDReader from this repository and trust the release. See [Apple's guidance for opening software that has not been notarized](https://support.apple.com/en-ca/102445).

Every release includes `SHA256SUMS`. Advanced users can verify the download from Terminal:

```bash
cd ~/Downloads
shasum -a 256 -c SHA256SUMS
```

## Build from Source

Building MDReader requires macOS 14 or later, Swift 6.2 or later, and Node.js 24.

```bash
git clone https://github.com/ZhangYueguang/MDReader.git
cd MDReader
bash scripts/build-app.sh
open dist/MDReader.app
```

The application is created at `dist/MDReader.app`. Local builds use ad hoc code signing and are not notarized with an Apple Developer ID.

To build the same disk image used by GitHub Releases:

```bash
bash scripts/build-dmg.sh
```

The DMG and checksum file are created in `release/`.

## Open Markdown Files

- Choose **Open With → MDReader** in Finder.
- Drag a `.md` or `.markdown` file onto the application icon or an existing reader window.
- Use **File → Open** or press `⌘O` in MDReader.

To open the bundled showcase document:

```bash
open -a dist/MDReader.app Tests/Fixtures/Showcase.md
```

## Edit and Save

1. Open a Markdown file and choose **Edit** in the window toolbar.
2. Edit the Markdown source directly. Syntax highlighting never changes the underlying text.
3. Use the fixed formatting bar for headings, bold, italic, strikethrough, links, quotes, code, math, and lists.
4. Choose **Read** to typeset the current in-memory source immediately.

MDReader participates in the native macOS document lifecycle. Changes are autosaved, and `⌘S` saves immediately. Undo, redo, find, spell checking, and standard text editing shortcuts behave like other Mac applications.

Existing UTF-8, UTF-16, and GB18030/GBK files keep their original encoding and byte-order-mark style whenever they are saved. Use **File → Convert to UTF-8** when you intentionally want UTF-8 output.

## Architecture

MDReader uses a SwiftUI document-based shell, a native TextKit editor, and a tightly controlled `WKWebView` rendering surface.

1. Swift decodes the source, preserves its text encoding, and uses the macOS document system for coordinated autosave.
2. TextKit provides source editing, selection-based formatting, undo, find, and lightweight syntax highlighting.
3. A bundled unified/remark pipeline parses Markdown, applies GFM extensions, and sanitizes embedded HTML.
4. Highlight.js-compatible output styles code blocks.
5. Bundled MathJax typesets TeX and MathML after the Markdown structure is ready.
6. Custom URL schemes expose only packaged resources and images inside the document directory.

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

MDReader intentionally does not provide WYSIWYG editing, split preview, folder navigation, document outlines, tabs, automatic external-file refresh, Mermaid rendering, or automatic updates yet.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

MDReader is available under the [MIT License](LICENSE).
