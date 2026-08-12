import Foundation
import MDReaderKit

func markdownFormattingTests() -> [TestCase] {
    [
        TestCase("Inline formatting wraps a selection and keeps it selected") {
            let cases: [(MarkdownFormatting.Action, String, String)] = [
                (.bold, "**word**", "word"),
                (.italic, "*word*", "word"),
                (.strikethrough, "~~word~~", "word"),
                (.inlineCode, "`word`", "word"),
                (.inlineMath, "$word$", "word"),
            ]
            for (action, expectedText, expectedSelection) in cases {
                let result = MarkdownFormatting.apply(
                    action,
                    to: "word",
                    selectedRange: NSRange(location: 0, length: 4)
                )
                try expectEqual(result.text, expectedText)
                try expectEqual(
                    (result.text as NSString).substring(with: result.selectedRange),
                    expectedSelection
                )
            }
        },
        TestCase("Inline formatting creates an editable placeholder") {
            let result = MarkdownFormatting.apply(
                .bold,
                to: "ab",
                selectedRange: NSRange(location: 1, length: 0)
            )
            try expectEqual(result.text, "a****b")
            try expectEqual(result.selectedRange, NSRange(location: 3, length: 0))
        },
        TestCase("Inline formatting removes a selected matching wrapper") {
            let result = MarkdownFormatting.apply(
                .bold,
                to: "**word**",
                selectedRange: NSRange(location: 0, length: 8)
            )
            try expectEqual(result.text, "word")
            try expectEqual(result.selectedRange, NSRange(location: 0, length: 4))
        },
        TestCase("Inline formatting removes a wrapper around the selection") {
            let result = MarkdownFormatting.apply(
                .bold,
                to: "Before **word** after",
                selectedRange: NSRange(location: 9, length: 4)
            )
            try expectEqual(result.text, "Before word after")
            try expectEqual(result.selectedRange, NSRange(location: 7, length: 4))
        },
        TestCase("Link formatting selects the destination placeholder") {
            let result = MarkdownFormatting.apply(
                .link,
                to: "Read docs",
                selectedRange: NSRange(location: 5, length: 4)
            )
            try expectEqual(result.text, "Read [docs](url)")
            try expectEqual(
                (result.text as NSString).substring(with: result.selectedRange),
                "url"
            )
        },
        TestCase("Display math and fenced code use block wrappers") {
            let math = MarkdownFormatting.apply(
                .displayMath,
                to: "x + y",
                selectedRange: NSRange(location: 0, length: 5)
            )
            try expectEqual(math.text, "$$\nx + y\n$$")
            try expectEqual(
                (math.text as NSString).substring(with: math.selectedRange),
                "x + y"
            )

            let code = MarkdownFormatting.apply(
                .codeBlock,
                to: "let x = 1",
                selectedRange: NSRange(location: 0, length: 9)
            )
            try expectEqual(code.text, "```\nlet x = 1\n```")
        },
        TestCase("Block wrappers toggle off") {
            let mathSource = "$$\nx + y\n$$"
            let math = MarkdownFormatting.apply(
                .displayMath,
                to: mathSource,
                selectedRange: NSRange(
                    location: 0,
                    length: (mathSource as NSString).length
                )
            )
            try expectEqual(math.text, "x + y")

            let codeSource = "```swift\nlet x = 1\n```"
            let code = MarkdownFormatting.apply(
                .codeBlock,
                to: codeSource,
                selectedRange: NSRange(
                    location: 0,
                    length: (codeSource as NSString).length
                )
            )
            try expectEqual(code.text, "let x = 1")
        },
        TestCase("Heading and quote formatting transform intersecting lines") {
            let heading = MarkdownFormatting.apply(
                .heading(level: 2),
                to: "First\nSecond",
                selectedRange: NSRange(location: 2, length: 8)
            )
            try expectEqual(heading.text, "## First\n## Second")

            let quote = MarkdownFormatting.apply(
                .blockQuote,
                to: "First\nSecond",
                selectedRange: NSRange(location: 0, length: 12)
            )
            try expectEqual(quote.text, "> First\n> Second")
        },
        TestCase("Matching heading and quote prefixes toggle off") {
            let heading = MarkdownFormatting.apply(
                .heading(level: 2),
                to: "## First\n## Second",
                selectedRange: NSRange(location: 0, length: 18)
            )
            try expectEqual(heading.text, "First\nSecond")

            let quote = MarkdownFormatting.apply(
                .blockQuote,
                to: "> First\n> Second",
                selectedRange: NSRange(location: 0, length: 16)
            )
            try expectEqual(quote.text, "First\nSecond")
        },
        TestCase("List formatting uses deterministic line prefixes") {
            let source = "Alpha\nBeta"
            let range = NSRange(location: 0, length: (source as NSString).length)
            try expectEqual(
                MarkdownFormatting.apply(.bulletedList, to: source, selectedRange: range).text,
                "- Alpha\n- Beta"
            )
            try expectEqual(
                MarkdownFormatting.apply(.numberedList, to: source, selectedRange: range).text,
                "1. Alpha\n2. Beta"
            )
            try expectEqual(
                MarkdownFormatting.apply(.taskList, to: source, selectedRange: range).text,
                "- [ ] Alpha\n- [ ] Beta"
            )
        },
        TestCase("List formatting replaces another Markdown list prefix") {
            let source = "- Alpha\n* Beta\n3. Gamma\n- [x] Delta"
            let range = NSRange(location: 0, length: (source as NSString).length)
            let result = MarkdownFormatting.apply(
                .numberedList,
                to: source,
                selectedRange: range
            )
            try expectEqual(
                result.text,
                "1. Alpha\n2. Beta\n3. Gamma\n4. Delta"
            )
        },
        TestCase("Matching list formatting toggles off") {
            let source = "- Alpha\n- Beta"
            let result = MarkdownFormatting.apply(
                .bulletedList,
                to: source,
                selectedRange: NSRange(
                    location: 0,
                    length: (source as NSString).length
                )
            )
            try expectEqual(result.text, "Alpha\nBeta")
        },
    ]
}
