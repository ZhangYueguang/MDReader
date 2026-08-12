import AppKit
import SwiftUI
import UniformTypeIdentifiers

public struct ReaderView: View {
    @ObservedObject private var document: MarkdownDocument
    private let fileURL: URL?
    private let isEditable: Bool
    @State private var status: ReaderStatus = .loading
    @State private var readerIdentity = UUID()
    @State private var mode: EditorMode = .defaultMode
    @StateObject private var commandCenter = EditorCommandCenter()

    public init(
        document: MarkdownDocument,
        fileURL: URL?,
        isEditable: Bool = true
    ) {
        self.document = document
        self.fileURL = fileURL
        self.isEditable = isEditable
    }

    public var body: some View {
        VStack(spacing: 0) {
            if mode.showsFormattingBar {
                FormattingBar(perform: commandCenter.send)
            }

            if mode.showsSourceEditor {
                MarkdownEditorView(
                    text: $document.text,
                    command: commandCenter.request
                )
            } else {
                readerSurface
            }
        }
        .frame(minWidth: 520, minHeight: 360)
        .navigationTitle(fileURL?.lastPathComponent ?? "Untitled.md")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("Mode", selection: $mode) {
                    ForEach(EditorMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue)
                            .tag(mode)
                            .disabled(!mode.isAvailable(isEditable: isEditable))
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .onChange(of: mode) { oldMode, newMode in
                    if oldMode == .edit, newMode == .read {
                        status = .loading
                        readerIdentity = UUID()
                    }
                }
            }
        }
        .onChange(of: isEditable) { _, editable in
            if !editable {
                mode = .read
            }
        }
        .onChange(of: mode) { _, newMode in
            if newMode == .edit, !isEditable {
                mode = .read
            }
        }
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: nil,
            perform: openDroppedDocuments
        )
        .focusedSceneObject(document)
    }

    private var readerSurface: some View {
        ZStack {
            Color(nsColor: ReaderTheme.paperColor)
                .ignoresSafeArea()

            ReaderWebView(
                source: document.text,
                fileURL: fileURL,
                onStatusChange: setStatus
            )
            .id(readerIdentity)
            .opacity(status == .ready ? 1 : 0)
            .allowsHitTesting(status == .ready)

            statusOverlay
        }
        .animation(.easeOut(duration: 0.22), value: status)
    }

    @ViewBuilder
    private var statusOverlay: some View {
        switch status {
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.small)
                Text("Typesetting…")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        case .ready:
            EmptyView()
        case let .failed(message):
            VStack(alignment: .leading, spacing: 16) {
                Text(fileURL?.lastPathComponent ?? "This document")
                    .font(.system(size: 18, weight: .semibold))
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Button("Reopen") {
                    status = .loading
                    readerIdentity = UUID()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: 420, alignment: .leading)
            .padding(32)
        }
    }

    private func setStatus(_ newStatus: ReaderStatus) {
        status = newStatus
    }

    private func openDroppedDocuments(_ providers: [NSItemProvider]) -> Bool {
        let matchingProviders = providers.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }
        for provider in matchingProviders {
            provider.loadItem(
                forTypeIdentifier: UTType.fileURL.identifier,
                options: nil
            ) { item, _ in
                guard let item,
                      let url = DroppedFileURL.decode(item),
                      MarkdownDocument.readableContentTypes.contains(where: {
                          $0.conforms(to: UTType(filenameExtension: url.pathExtension) ?? .data)
                      }) else {
                    return
                }
                Task { @MainActor in
                    NSDocumentController.shared.openDocument(
                        withContentsOf: url,
                        display: true
                    ) { _, _, _ in }
                }
            }
        }
        return !matchingProviders.isEmpty
    }
}
