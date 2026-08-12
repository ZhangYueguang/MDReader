import Foundation
import MDReaderKit

func markdownSyntaxHighlighterTests() -> [TestCase] {
    [
        TestCase("Syntax highlighter identifies Markdown structures") {
            let source = """
            # Heading
            > Quote
            - item
            **bold** and *italic* and ~~old~~
            [docs](https://example.com) and `code`
            $x + y$ and $$z$$
            <!-- note -->
            """
            let kinds = Set(
                MarkdownSyntaxHighlighter.tokens(in: source).map(\.kind)
            )
            try expectEqual(
                kinds,
                Set([
                    .heading,
                    .quote,
                    .listMarker,
                    .strong,
                    .emphasis,
                    .strikethrough,
                    .link,
                    .code,
                    .math,
                    .comment,
                ])
            )
        },
        TestCase("Syntax highlighter identifies fenced code as one block") {
            let source = "Before\n```swift\nlet x = 1\n```\nAfter"
            let tokens = MarkdownSyntaxHighlighter.tokens(in: source)
                .filter { $0.kind == .codeBlock }
            try expectEqual(tokens.count, 1)
            try expectEqual(
                (source as NSString).substring(with: tokens[0].range),
                "```swift\nlet x = 1\n```"
            )
        },
        TestCase("Syntax token ranges use UTF-16 coordinates") {
            let source = "🙂 text **bold**"
            let token = MarkdownSyntaxHighlighter.tokens(in: source)
                .first { $0.kind == .strong }
            guard let token else {
                throw TestFailure("Expected a strong token")
            }
            try expectEqual(token.range, NSRange(location: 8, length: 8))
            try expectEqual(
                (source as NSString).substring(with: token.range),
                "**bold**"
            )
        },
        TestCase("Syntax highlighting leaves source text unchanged") {
            let source = "# \u{6807}\u{9898}\n\n$E = mc^2$"
            _ = MarkdownSyntaxHighlighter.tokens(in: source)
            try expectEqual(source, "# \u{6807}\u{9898}\n\n$E = mc^2$")
        },
    ]
}
