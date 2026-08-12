import Foundation
import SwiftUI
import UniformTypeIdentifiers

public enum MarkdownDocumentError: LocalizedError {
    case notARegularFile
    case unsupportedEncoding

    public var errorDescription: String? {
        switch self {
        case .notARegularFile:
            "Unable to read this Markdown file."
        case .unsupportedEncoding:
            "Unable to determine the file encoding."
        }
    }
}

public final class MarkdownDocument: ReferenceFileDocument, @unchecked Sendable {
    public struct Snapshot: Sendable {
        public let text: String
        public let encoding: DetectedEncoding
        public let hasByteOrderMark: Bool

        public func encodedData() throws -> Data {
            try encoding.encode(text, byteOrderMark: hasByteOrderMark)
        }
    }

    public static let readableContentTypes: [UTType] = [
        UTType(importedAs: "net.daringfireball.markdown")
    ]
    public static let writableContentTypes = readableContentTypes

    @Published public var text: String
    @Published public private(set) var encoding: DetectedEncoding
    @Published public private(set) var hasByteOrderMark: Bool

    public init(text: String) {
        self.text = text
        self.encoding = .utf8
        self.hasByteOrderMark = false
    }

    public init(data: Data) throws {
        let decoded = try TextDecoder.decode(data)
        self.text = decoded.text
        self.encoding = decoded.encoding
        self.hasByteOrderMark = decoded.hasByteOrderMark
    }

    public convenience init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw MarkdownDocumentError.notARegularFile
        }
        try self.init(data: data)
    }

    public func snapshot(contentType _: UTType) throws -> Snapshot {
        Snapshot(
            text: text,
            encoding: encoding,
            hasByteOrderMark: hasByteOrderMark
        )
    }

    public func fileWrapper(
        snapshot: Snapshot,
        configuration _: WriteConfiguration
    ) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try snapshot.encodedData())
    }

    public func convertToUTF8() {
        encoding = .utf8
        hasByteOrderMark = false
    }
}
