import Foundation
import MDReaderKit

func textDecoderTests() -> [TestCase] {
    [
        TestCase("Text decoder reads UTF-8 and strips its BOM") {
            let plain = try TextDecoder.decode(Data("# Heading".utf8))
            try expectEqual(
                plain,
                DecodedText(text: "# Heading", encoding: .utf8, hasByteOrderMark: false)
            )

            let withBOM = Data([0xEF, 0xBB, 0xBF]) + Data("Body".utf8)
            let bom = try TextDecoder.decode(withBOM)
            try expectEqual(
                bom,
                DecodedText(text: "Body", encoding: .utf8, hasByteOrderMark: true)
            )
        },
        TestCase("Text decoder reads little and big endian UTF-16") {
            let multibyteText = "\u{4E2D}\u{6587}"
            let littleEndian = Data([0xFF, 0xFE, 0x2D, 0x4E, 0x87, 0x65])
            let bigEndian = Data([0xFE, 0xFF, 0x4E, 0x2D, 0x65, 0x87])

            try expectEqual(
                TextDecoder.decode(littleEndian),
                DecodedText(
                    text: multibyteText,
                    encoding: .utf16LittleEndian,
                    hasByteOrderMark: true
                )
            )
            try expectEqual(
                TextDecoder.decode(bigEndian),
                DecodedText(
                    text: multibyteText,
                    encoding: .utf16BigEndian,
                    hasByteOrderMark: true
                )
            )
        },
        TestCase("Text decoder reads GB18030 multibyte text") {
            let multibyteText = "\u{4E2D}\u{6587}"
            let decoded = try TextDecoder.decode(Data([0xD6, 0xD0, 0xCE, 0xC4]))
            try expectEqual(
                decoded,
                DecodedText(
                    text: multibyteText,
                    encoding: .gb18030,
                    hasByteOrderMark: false
                )
            )
        },
        TestCase("Text encoder preserves UTF byte order marks") {
            try expectEqual(
                try DetectedEncoding.utf8.encode("Body", byteOrderMark: true),
                Data([0xEF, 0xBB, 0xBF]) + Data("Body".utf8)
            )
            try expectEqual(
                try DetectedEncoding.utf16LittleEndian.encode(
                    "A",
                    byteOrderMark: true
                ),
                Data([0xFF, 0xFE, 0x41, 0x00])
            )
            try expectEqual(
                try DetectedEncoding.utf16BigEndian.encode(
                    "A",
                    byteOrderMark: true
                ),
                Data([0xFE, 0xFF, 0x00, 0x41])
            )
        },
        TestCase("Text encoder round trips GB18030") {
            let text = "\u{4E2D}\u{6587}"
            let encoded = try DetectedEncoding.gb18030.encode(
                text,
                byteOrderMark: false
            )
            try expectEqual(encoded, Data([0xD6, 0xD0, 0xCE, 0xC4]))
            try expectEqual(try TextDecoder.decode(encoded).text, text)
        },
        TestCase("Text encoder preserves Unicode through GB18030") {
            let text = "A \u{1F642}"
            let encoded = try DetectedEncoding.gb18030.encode(
                text,
                byteOrderMark: false
            )
            try expectEqual(try TextDecoder.decode(encoded).text, text)
        },
        TestCase("Text decoder rejects incomplete bytes") {
            try expectThrows(TextDecodingError.self) {
                _ = try TextDecoder.decode(Data([0x81]))
            }
        }
    ]
}
