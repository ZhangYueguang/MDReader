import MDReaderKit
import UniformTypeIdentifiers

func markdownDocumentTests() -> [TestCase] {
    [
        TestCase("Markdown document writes the Markdown content type") {
            try expectEqual(
                MarkdownDocument.writableContentTypes.map(\.identifier),
                ["net.daringfireball.markdown"]
            )
        },
        TestCase("Markdown document registers the Markdown content type") {
            try expectEqual(
                MarkdownDocument.readableContentTypes.map(\.identifier),
                ["net.daringfireball.markdown"]
            )
        },
        TestCase("Markdown document keeps source text verbatim") {
            let document = MarkdownDocument(text: "# Heading\n\n$E = mc^2$")
            try expectEqual(document.text, "# Heading\n\n$E = mc^2$")
            document.text += "\n"
            try expectEqual(document.text, "# Heading\n\n$E = mc^2$\n")
        },
        TestCase("Markdown document records detected source encoding") {
            let multibyteText = "\u{4E2D}\u{6587}"
            let document = try MarkdownDocument(
                data: Data([0xD6, 0xD0, 0xCE, 0xC4])
            )
            try expectEqual(document.text, multibyteText)
            try expectEqual(document.encoding, .gb18030)
            try expectEqual(document.hasByteOrderMark, false)
        },
        TestCase("Markdown document snapshot preserves source encoding") {
            let document = try MarkdownDocument(
                data: Data([0xFF, 0xFE, 0x41, 0x00])
            )
            document.text = "AB"
            let snapshot = try document.snapshot(
                contentType: MarkdownDocument.writableContentTypes[0]
            )
            try expectEqual(
                try snapshot.encodedData(),
                Data([0xFF, 0xFE, 0x41, 0x00, 0x42, 0x00])
            )
        },
        TestCase("Markdown document converts its target encoding to UTF-8") {
            let document = try MarkdownDocument(
                data: Data([0xD6, 0xD0, 0xCE, 0xC4])
            )
            document.convertToUTF8()
            try expectEqual(document.encoding, .utf8)
            try expectEqual(document.hasByteOrderMark, false)
            let snapshot = try document.snapshot(
                contentType: MarkdownDocument.writableContentTypes[0]
            )
            try expectEqual(try snapshot.encodedData(), Data("\u{4E2D}\u{6587}".utf8))
        }
    ]
}
