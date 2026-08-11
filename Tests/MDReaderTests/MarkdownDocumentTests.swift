import MDReaderKit
import UniformTypeIdentifiers

func markdownDocumentTests() -> [TestCase] {
    [
        TestCase("Markdown document exposes no writable types") {
            try expectEqual(MarkdownDocument.writableContentTypes, [])
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
        },
        TestCase("Markdown document records detected source encoding") {
            let multibyteText = "\u{4E2D}\u{6587}"
            let document = try MarkdownDocument(
                data: Data([0xD6, 0xD0, 0xCE, 0xC4])
            )
            try expectEqual(document.text, multibyteText)
            try expectEqual(document.encoding, .gb18030)
        }
    ]
}
