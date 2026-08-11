import Foundation
import MDReaderKit

func localResourceResolverTests() -> [TestCase] {
    [
        TestCase("Local resolver accepts descendants and decoded spaces") {
            let root = URL(fileURLWithPath: "/tmp/mdreader-doc", isDirectory: true)
            let resolver = LocalResourceResolver(baseDirectory: root)

            try expectEqual(
                resolver.resolve(relativePath: "images/plot%201.png")?.path,
                "/tmp/mdreader-doc/images/plot 1.png"
            )
        },
        TestCase("Local resolver rejects traversal and absolute paths") {
            let root = URL(fileURLWithPath: "/tmp/mdreader-doc", isDirectory: true)
            let resolver = LocalResourceResolver(baseDirectory: root)

            try expectEqual(resolver.resolve(relativePath: "../secret.png"), nil)
            try expectEqual(resolver.resolve(relativePath: "/etc/passwd"), nil)
            try expectEqual(resolver.resolve(relativePath: "images/../../secret.png"), nil)
        },
        TestCase("Local resolver rejects a symlink that escapes the document folder") {
            let fileManager = FileManager.default
            let temporaryRoot = fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            let documentRoot = temporaryRoot.appendingPathComponent("document", isDirectory: true)
            let outsideRoot = temporaryRoot.appendingPathComponent("outside", isDirectory: true)
            try fileManager.createDirectory(at: documentRoot, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: outsideRoot, withIntermediateDirectories: true)
            try fileManager.createSymbolicLink(
                at: documentRoot.appendingPathComponent("escape"),
                withDestinationURL: outsideRoot
            )
            defer { try? fileManager.removeItem(at: temporaryRoot) }

            let resolver = LocalResourceResolver(baseDirectory: documentRoot)
            try expectEqual(resolver.resolve(relativePath: "escape/private.png"), nil)
        },
        TestCase("Reader MIME types cover scripts fonts and images") {
            try expectEqual(MIMEType.forExtension("js"), "text/javascript")
            try expectEqual(MIMEType.forExtension("css"), "text/css")
            try expectEqual(MIMEType.forExtension("svg"), "image/svg+xml")
            try expectEqual(MIMEType.forExtension("woff2"), "font/woff2")
            try expectEqual(MIMEType.forExtension("unknown"), "application/octet-stream")
        }
    ]
}
