import AppKit
import SwiftUI
import UniformTypeIdentifiers

public struct ReaderView: View {
    private let document: MarkdownDocument
    private let fileURL: URL?
    @State private var status: ReaderStatus = .loading
    @State private var readerIdentity = UUID()

    public init(document: MarkdownDocument, fileURL: URL?) {
        self.document = document
        self.fileURL = fileURL
    }

    public var body: some View {
        ZStack {
            Color(nsColor: ReaderTheme.paperColor)
                .ignoresSafeArea()

            ReaderWebView(
                document: document,
                fileURL: fileURL,
                onStatusChange: setStatus
            )
            .id(readerIdentity)
            .opacity(status == .ready ? 1 : 0)
            .allowsHitTesting(status == .ready)

            statusOverlay
        }
        .frame(minWidth: 520, minHeight: 360)
        .navigationTitle(fileURL?.lastPathComponent ?? "MDReader")
        .animation(.easeOut(duration: 0.22), value: status)
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: nil,
            perform: openDroppedDocuments
        )
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
