import Foundation
import MDReaderKit

func localImageResourceTests() -> [TestCase] {
    [
        TestCase("Absolute image loader validates bytes rather than file extensions") {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }
            let valid = root.appendingPathComponent("中文 100%#?.gif")
            let gif = Data(base64Encoded: "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7")!
            try gif.write(to: valid)
            try expectEqual(LocalImageResource.load(from: valid)?.mimeType, "image/gif")
            let fake = root.appendingPathComponent("private.png")
            try Data("{\"secret\":\"not an image\"}".utf8).write(to: fake)
            try expectEqual(LocalImageResource.load(from: fake)?.data, nil)
            try expectEqual(LocalImageResource.load(from: root)?.data, nil)
            try expectEqual(LocalImageResource.load(from: root.appendingPathComponent("missing.png"))?.data, nil)
            try MainActor.assumeIsolated {
                let handler = ReaderSchemeHandler(resourceRoot: root, documentDirectory: root)
                let encoded = URLComponents(url: valid, resolvingAgainstBaseURL: false)!.percentEncodedPath
                let request = URL(string: "mdreader-file://image" + encoded)!
                try expectEqual(handler.resolvedURL(for: request)?.path, valid.path)
                try expectEqual(NavigationPolicy.decision(for: request, isMainFrame: true), .cancel)
                try expectEqual(NavigationPolicy.decision(for: request, isMainFrame: false), .allow)
                try expectEqual(handler.resolvedURL(for: URL(string: "mdreader-file://image/%00.png")!), nil)
            }
        }
    ]
}
