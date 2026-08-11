import CoreFoundation
import Foundation

public enum DetectedEncoding: String, Equatable, Sendable {
    case utf8 = "UTF-8"
    case utf16LittleEndian = "UTF-16 LE"
    case utf16BigEndian = "UTF-16 BE"
    case gb18030 = "GB18030"
}

public struct DecodedText: Equatable, Sendable {
    public let text: String
    public let encoding: DetectedEncoding

    public init(text: String, encoding: DetectedEncoding) {
        self.text = text
        self.encoding = encoding
    }
}

public enum TextDecodingError: LocalizedError {
    case unsupportedEncoding

    public var errorDescription: String? {
        "Unable to determine the file encoding. Supported encodings are UTF-8, UTF-16, and GB18030."
    }
}

public enum TextDecoder {
    private static let utf8BOM = Data([0xEF, 0xBB, 0xBF])
    private static let utf16LittleEndianBOM = Data([0xFF, 0xFE])
    private static let utf16BigEndianBOM = Data([0xFE, 0xFF])
    private static let gb18030 = String.Encoding(
        rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x0632))
    )

    public static func decode(_ data: Data) throws -> DecodedText {
        if data.starts(with: utf8BOM) {
            return try decoded(
                data.dropFirst(utf8BOM.count),
                using: .utf8,
                detectedAs: .utf8
            )
        }
        if data.starts(with: utf16LittleEndianBOM) {
            return try decoded(
                data.dropFirst(utf16LittleEndianBOM.count),
                using: .utf16LittleEndian,
                detectedAs: .utf16LittleEndian
            )
        }
        if data.starts(with: utf16BigEndianBOM) {
            return try decoded(
                data.dropFirst(utf16BigEndianBOM.count),
                using: .utf16BigEndian,
                detectedAs: .utf16BigEndian
            )
        }
        if let text = String(data: data, encoding: .utf8) {
            return DecodedText(text: text, encoding: .utf8)
        }
        if let encoding = likelyUTF16Encoding(for: data),
           let text = String(data: data, encoding: encoding.stringEncoding) {
            return DecodedText(text: text, encoding: encoding.detectedEncoding)
        }
        if let text = String(data: data, encoding: gb18030) {
            return DecodedText(text: text, encoding: .gb18030)
        }
        throw TextDecodingError.unsupportedEncoding
    }

    private static func decoded(
        _ bytes: Data.SubSequence,
        using encoding: String.Encoding,
        detectedAs detectedEncoding: DetectedEncoding
    ) throws -> DecodedText {
        guard let text = String(data: Data(bytes), encoding: encoding) else {
            throw TextDecodingError.unsupportedEncoding
        }
        return DecodedText(text: text, encoding: detectedEncoding)
    }

    private static func likelyUTF16Encoding(
        for data: Data
    ) -> (stringEncoding: String.Encoding, detectedEncoding: DetectedEncoding)? {
        guard data.count >= 4, data.count.isMultiple(of: 2) else {
            return nil
        }

        var evenZeroes = 0
        var oddZeroes = 0
        for (index, byte) in data.enumerated() where byte == 0 {
            if index.isMultiple(of: 2) {
                evenZeroes += 1
            } else {
                oddZeroes += 1
            }
        }

        let pairs = data.count / 2
        if oddZeroes * 4 >= pairs && evenZeroes == 0 {
            return (.utf16LittleEndian, .utf16LittleEndian)
        }
        if evenZeroes * 4 >= pairs && oddZeroes == 0 {
            return (.utf16BigEndian, .utf16BigEndian)
        }
        return nil
    }
}
