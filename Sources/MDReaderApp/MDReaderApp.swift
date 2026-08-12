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
        DocumentGroup(newDocument: { MarkdownDocument(text: "") }) { configuration in
            ReaderView(
                document: configuration.document,
                fileURL: configuration.fileURL,
                isEditable: configuration.isEditable
            )
        }
        .defaultSize(width: 900, height: 720)
        .commands {
            CommandGroup(after: .saveItem) {
                ConvertToUTF8Command()
            }
        }
    }
}

private struct ConvertToUTF8Command: View {
    @FocusedObject private var document: MarkdownDocument?

    var body: some View {
        Button("Convert to UTF-8") {
            document?.convertToUTF8()
        }
        .disabled(document == nil || document?.encoding == .utf8)
    }
}
