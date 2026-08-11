import Foundation

public struct LocalResourceResolver: Sendable {
    private let baseDirectory: URL
    private let basePath: String

    public init(baseDirectory: URL) {
        let resolvedBase = baseDirectory
            .standardizedFileURL
            .resolvingSymlinksInPath()
        self.baseDirectory = resolvedBase
        self.basePath = resolvedBase.path
    }

    public func resolve(relativePath: String) -> URL? {
        let pathWithoutSuffix = relativePath
            .split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)[0]
            .split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)[0]
        guard let decodedPath = String(pathWithoutSuffix).removingPercentEncoding,
              !decodedPath.isEmpty,
              !decodedPath.hasPrefix("/"),
              !containsSymbolicLink(in: decodedPath) else {
            return nil
        }

        let candidate = baseDirectory
            .appendingPathComponent(decodedPath)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let candidatePath = candidate.path
        guard candidatePath == basePath || candidatePath.hasPrefix(basePath + "/") else {
            return nil
        }
        return candidate
    }

    private func containsSymbolicLink(in relativePath: String) -> Bool {
        var cursor = baseDirectory
        for component in relativePath.split(separator: "/", omittingEmptySubsequences: true) {
            cursor.appendPathComponent(String(component))
            guard let attributes = try? FileManager.default.attributesOfItem(
                atPath: cursor.path
            ) else {
                continue
            }
            if attributes[.type] as? FileAttributeType == .typeSymbolicLink {
                return true
            }
        }
        return false
    }
}

public enum MIMEType {
    public static func forExtension(_ fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "html", "htm": "text/html"
        case "css": "text/css"
        case "js", "mjs": "text/javascript"
        case "json": "application/json"
        case "svg": "image/svg+xml"
        case "png": "image/png"
        case "jpg", "jpeg": "image/jpeg"
        case "gif": "image/gif"
        case "webp": "image/webp"
        case "avif": "image/avif"
        case "woff": "font/woff"
        case "woff2": "font/woff2"
        case "ttf": "font/ttf"
        case "otf": "font/otf"
        case "txt", "md", "markdown": "text/plain"
        default: "application/octet-stream"
        }
    }
}
