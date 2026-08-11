import AppKit
import SwiftUI
@preconcurrency import WebKit

public struct ReaderWebView: NSViewRepresentable {
    private let payload: ReaderPayload
    private let documentDirectory: URL?
    private let onStatusChange: (ReaderStatus) -> Void

    public init(
        document: MarkdownDocument,
        fileURL: URL?,
        onStatusChange: @escaping (ReaderStatus) -> Void
    ) {
        self.payload = ReaderPayload(
            source: document.text,
            title: fileURL?.lastPathComponent ?? "MDReader"
        )
        self.documentDirectory = fileURL?.deletingLastPathComponent()
        self.onStatusChange = onStatusChange
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            payload: payload,
            documentDirectory: documentDirectory,
            onStatusChange: onStatusChange
        )
    }

    public func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.setURLSchemeHandler(
            context.coordinator.schemeHandler,
            forURLScheme: "mdreader-resource"
        )
        configuration.setURLSchemeHandler(
            context.coordinator.schemeHandler,
            forURLScheme: "mdreader-file"
        )
        configuration.userContentController.add(
            context.coordinator,
            name: Coordinator.messageHandlerName
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsMagnification = true
        webView.magnification = 1
        webView.underPageBackgroundColor = ReaderTheme.paperColor
        context.coordinator.attach(webView)

        if let indexURL = URL(string: "mdreader-resource://app/index.html") {
            webView.load(URLRequest(url: indexURL))
        } else {
            onStatusChange(.failed(message: "The reader page URL is invalid."))
        }
        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(
            payload: payload,
            onStatusChange: onStatusChange
        )
        webView.underPageBackgroundColor = ReaderTheme.paperColor
    }

    public static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: Coordinator.messageHandlerName
        )
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        coordinator.detach()
    }

    @MainActor
    public final class Coordinator: NSObject,
        WKScriptMessageHandler,
        WKNavigationDelegate,
        WKUIDelegate
    {
        fileprivate static let messageHandlerName = "reader"

        fileprivate let schemeHandler: ReaderSchemeHandler
        private weak var webView: WKWebView?
        private var payload: ReaderPayload
        private var onStatusChange: (ReaderStatus) -> Void
        private var hasRendered = false

        fileprivate init(
            payload: ReaderPayload,
            documentDirectory: URL?,
            onStatusChange: @escaping (ReaderStatus) -> Void
        ) {
            self.payload = payload
            self.schemeHandler = ReaderSchemeHandler(
                documentDirectory: documentDirectory
            )
            self.onStatusChange = onStatusChange
        }

        fileprivate func attach(_ webView: WKWebView) {
            self.webView = webView
            onStatusChange(.loading)
        }

        fileprivate func detach() {
            webView = nil
        }

        fileprivate func update(
            payload: ReaderPayload,
            onStatusChange: @escaping (ReaderStatus) -> Void
        ) {
            self.payload = payload
            self.onStatusChange = onStatusChange
        }

        public func userContentController(
            _: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == Self.messageHandlerName,
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String else {
                return
            }

            switch type {
            case "ready":
                renderIfNeeded()
            case "error":
                let message = safeMessage(body["message"] as? String)
                onStatusChange(.failed(message: message))
            default:
                break
            }
        }

        public func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            switch NavigationPolicy.decision(for: url, isMainFrame: isMainFrame) {
            case .allow:
                decisionHandler(.allow)
            case .cancel:
                decisionHandler(.cancel)
            case let .openExternally(externalURL):
                decisionHandler(.cancel)
                NSWorkspace.shared.open(externalURL)
            }
        }

        public func webView(
            _: WKWebView,
            createWebViewWith _: WKWebViewConfiguration,
            for _: WKNavigationAction,
            windowFeatures _: WKWindowFeatures
        ) -> WKWebView? {
            nil
        }

        public func webView(
            _: WKWebView,
            didFailProvisionalNavigation _: WKNavigation?,
            withError _: Error
        ) {
            onStatusChange(.failed(message: "The reader page failed to load. Reopen the document."))
        }

        private func renderIfNeeded() {
            guard !hasRendered, let webView else { return }
            hasRendered = true
            Task { @MainActor [weak self, weak webView] in
                guard let self, let webView else { return }
                do {
                    _ = try await webView.callAsyncJavaScript(
                        "return await window.MDReader.render({source, title});",
                        arguments: [
                            "source": payload.source,
                            "title": payload.title
                        ],
                        in: nil,
                        contentWorld: .page
                    )
                    self.onStatusChange(.ready)
                } catch {
                    self.onStatusChange(
                        .failed(message: "Typesetting failed. Check the Markdown and math syntax.")
                    )
                }
            }
        }

        private func safeMessage(_ message: String?) -> String {
            guard let message else {
                return "An error occurred while typesetting the document."
            }
            let firstLine = message.split(whereSeparator: \.isNewline).first.map(String.init)
                ?? "An error occurred while typesetting the document."
            return String(firstLine.prefix(160))
        }
    }
}
