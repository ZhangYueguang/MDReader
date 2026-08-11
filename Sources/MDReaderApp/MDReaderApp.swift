import AppKit
import MDReaderKit
import SwiftUI

private final class MDReaderApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard let iconURL = Bundle.main.url(forResource: "MDReader", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL) else {
            return
        }
        NSApplication.shared.applicationIconImage = icon
    }
}

@main
struct MDReaderApp: App {
    @NSApplicationDelegateAdaptor(MDReaderApplicationDelegate.self)
    private var applicationDelegate

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { configuration in
            ReaderView(
                document: configuration.document,
                fileURL: configuration.fileURL
            )
        }
        .defaultSize(width: 900, height: 720)
    }
}
