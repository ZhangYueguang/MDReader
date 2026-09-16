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
              let fileURL = resolvedURL(for: url) else {
            fail(urlSchemeTask)
            return
        }

        let data: Data
        let mimeType: String
        if url.scheme == "mdreader-file", url.host == "image" {
            guard let image = LocalImageResource.load(from: fileURL) else {
                fail(urlSchemeTask)
                return
            }
            data = image.data
            mimeType = image.mimeType
        } else {
            guard let contents = try? Data(contentsOf: fileURL) else {
                fail(urlSchemeTask)
                return
            }
            data = contents
            mimeType = MIMEType.forExtension(fileURL.pathExtension)
        }

        let response = URLResponse(
            url: url,
            mimeType: mimeType,
            expectedContentLength: data.count,
            textEncodingName: mimeType.hasPrefix("text/") || mimeType == "image/svg+xml" ? "utf-8" : nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    private func fail(_ urlSchemeTask: any WKURLSchemeTask) {
        urlSchemeTask.didFailWithError(
            NSError(
                domain: "MDReader.Resource",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "The reading resource is missing, inaccessible, or not a supported image."]
            )
        )
    }

    public func webView(_: WKWebView, stop _: any WKURLSchemeTask) {}

    public func resolvedURL(for url: URL) -> URL? {
        // URL.path decodes escapes; the resolver must receive the encoded path
        // so literal %, # and ? in filenames are decoded once, not reinterpreted.
        guard let encodedPath = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedPath else {
            return nil
        }
        switch url.scheme {
        case "mdreader-resource":
            guard let host = url.host, host == "app" || host == "mathjax" else {
                return nil
            }
            return resourceResolver.resolve(
                relativePath: host + "/" + encodedPath.dropFirst()
            )
        case "mdreader-file":
            if url.host == "image" {
                guard let path = encodedPath.removingPercentEncoding,
                      path.hasPrefix("/"), !path.hasPrefix("//"),
                      !path.contains("\0") else { return nil }
                return URL(fileURLWithPath: path).standardizedFileURL
            }
            guard url.host == "document", let documentResolver else {
                return nil
            }
            return documentResolver.resolve(
                relativePath: String(encodedPath.dropFirst())
            )
        default:
            return nil
        }
    }
}
