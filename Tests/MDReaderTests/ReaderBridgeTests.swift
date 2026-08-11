import Foundation
import MDReaderKit

func readerBridgeTests() -> [TestCase] {
    [
        TestCase("Reader payload keeps Markdown verbatim") {
            let source = "# Heading\n\n$\\frac{1}{2}$\n\n<script>blocked()</script>"
            let payload = ReaderPayload(source: source, title: "demo.md")

            try expectEqual(payload.source, source)
            try expectEqual(payload.title, "demo.md")
        },
        TestCase("Navigation policy opens external links outside the reader") {
            let webURL = URL(string: "https://example.com/docs")!
            let mailURL = URL(string: "mailto:reader@example.com")!

            try expectEqual(
                NavigationPolicy.decision(for: webURL, isMainFrame: true),
                .openExternally(webURL)
            )
            try expectEqual(
                NavigationPolicy.decision(for: mailURL, isMainFrame: true),
                .openExternally(mailURL)
            )
        },
        TestCase("Navigation policy allows reader resources and image subresources") {
            let appURL = URL(string: "mdreader-resource://app/index.html")!
            let localImage = URL(string: "mdreader-file://document/images/a.png")!
            let remoteImage = URL(string: "https://example.com/a.png")!

            try expectEqual(
                NavigationPolicy.decision(for: appURL, isMainFrame: true),
                .allow
            )
            try expectEqual(
                NavigationPolicy.decision(for: localImage, isMainFrame: false),
                .allow
            )
            try expectEqual(
                NavigationPolicy.decision(for: remoteImage, isMainFrame: false),
                .allow
            )
        },
        TestCase("Navigation policy blocks executable and unknown schemes") {
            try expectEqual(
                NavigationPolicy.decision(
                    for: URL(string: "javascript:alert(1)")!,
                    isMainFrame: true
                ),
                .cancel
            )
            try expectEqual(
                NavigationPolicy.decision(
                    for: URL(string: "file:///etc/passwd")!,
                    isMainFrame: true
                ),
                .cancel
            )
        },
        TestCase("Dropped Markdown file accepts URL and URL data representations") {
            let url = URL(fileURLWithPath: "/tmp/reading/demo.md")

            try expectEqual(DroppedFileURL.decode(url as NSURL), url)
            try expectEqual(DroppedFileURL.decode(url.dataRepresentation as NSData), url)
        }
    ]
}
