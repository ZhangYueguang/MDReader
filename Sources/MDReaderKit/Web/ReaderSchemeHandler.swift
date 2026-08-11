import Foundation
@preconcurrency import WebKit

public final class ReaderSchemeHandler: NSObject, WKURLSchemeHandler {
    private let resourceResolver: LocalResourceResolver
    private let documentResolver: LocalResourceResolver?

    public convenience init(documentDirectory: URL?) {
        let resourceRoot = ReaderResourceLocator.resourcesForCurrentProcess()
        self.init(resourceRoot: resourceRoot, documentDirectory: documentDirectory)
    }

    public init(resourceRoot: URL, documentDirectory: URL?) {
        self.resourceResolver = LocalResourceResolver(baseDirectory: resourceRoot)
        self.documentResolver = documentDirectory.map(LocalResourceResolver.init)
        super.init()
    }

    public func webView(_: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              let fileURL = resolvedURL(for: url),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(
                NSError(
                    domain: "MDReader.Resource",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "The reading resource is missing or inaccessible."]
                )
            )
            return
        }

        let response = URLResponse(
            url: url,
            mimeType: MIMEType.forExtension(fileURL.pathExtension),
            expectedContentLength: data.count,
            textEncodingName: isTextFile(fileURL) ? "utf-8" : nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    public func webView(_: WKWebView, stop _: any WKURLSchemeTask) {}

    private func resolvedURL(for url: URL) -> URL? {
        switch url.scheme {
        case "mdreader-resource":
            guard let host = url.host, host == "app" || host == "mathjax" else {
                return nil
            }
            return resourceResolver.resolve(
                relativePath: host + "/" + url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            )
        case "mdreader-file":
            guard url.host == "document", let documentResolver else {
                return nil
            }
            return documentResolver.resolve(
                relativePath: url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            )
        default:
            return nil
        }
    }

    private func isTextFile(_ url: URL) -> Bool {
        ["html", "htm", "css", "js", "mjs", "json", "svg", "txt"].contains(
            url.pathExtension.lowercased()
        )
    }
}
