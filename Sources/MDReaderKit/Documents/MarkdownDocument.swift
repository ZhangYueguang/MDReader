import Foundation
import SwiftUI
import UniformTypeIdentifiers

public enum MarkdownDocumentError: LocalizedError {
    case notARegularFile
    case unsupportedEncoding
    case readOnly

    public var errorDescription: String? {
        switch self {
        case .notARegularFile:
            "Unable to read this Markdown file."
        case .unsupportedEncoding:
            "Unable to determine the file encoding."
        case .readOnly:
            "MDReader is read-only and never modifies the source file."
        }
    }
}

public struct MarkdownDocument: FileDocument, Sendable {
    public static let readableContentTypes: [UTType] = [
        UTType(importedAs: "net.daringfireball.markdown")
    ]
    public static let writableContentTypes: [UTType] = []

    public let text: String
    public let sourceData: Data
    public let encoding: DetectedEncoding

    public init(text: String) {
        self.text = text
        self.sourceData = Data(text.utf8)
        self.encoding = .utf8
    }

    public init(data: Data) throws {
        let decoded = try TextDecoder.decode(data)
        self.text = decoded.text
        self.sourceData = data
        self.encoding = decoded.encoding
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw MarkdownDocumentError.notARegularFile
        }
        try self.init(data: data)
    }

    public func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        throw MarkdownDocumentError.readOnly
    }
}
