import Foundation

public struct ReaderPayload: Equatable, Sendable {
    public let source: String
    public let title: String

    public init(source: String, title: String) {
        self.source = source
        self.title = title
    }
}

public enum ReaderStatus: Equatable, Sendable {
    case loading
    case ready
    case failed(message: String)
}

public enum NavigationDecision: Equatable, Sendable {
    case allow
    case cancel
    case openExternally(URL)
}

public enum NavigationPolicy {
    public static func decision(
        for url: URL,
        isMainFrame: Bool
    ) -> NavigationDecision {
        switch url.scheme?.lowercased() {
        case "mdreader-resource":
            guard let host = url.host, host == "app" || host == "mathjax" else {
                return .cancel
            }
            return .allow
        case "mdreader-file":
            return !isMainFrame && url.host == "document" ? .allow : .cancel
        case "http", "https":
            return isMainFrame ? .openExternally(url) : .allow
        case "mailto":
            return isMainFrame ? .openExternally(url) : .cancel
        default:
            return .cancel
        }
    }
}

public enum DroppedFileURL {
    public static func decode(_ item: NSSecureCoding) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        if let value = item as? String {
            return URL(string: value)
        }
        return nil
    }
}
