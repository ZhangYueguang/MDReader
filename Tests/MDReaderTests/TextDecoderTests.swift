import Foundation
import MDReaderKit

func textDecoderTests() -> [TestCase] {
    [
        TestCase("Text decoder reads UTF-8 and strips its BOM") {
            let plain = try TextDecoder.decode(Data("# Heading".utf8))
            try expectEqual(plain, DecodedText(text: "# Heading", encoding: .utf8))

            let withBOM = Data([0xEF, 0xBB, 0xBF]) + Data("Body".utf8)
            let bom = try TextDecoder.decode(withBOM)
            try expectEqual(bom, DecodedText(text: "Body", encoding: .utf8))
        },
        TestCase("Text decoder reads little and big endian UTF-16") {
            let multibyteText = "\u{4E2D}\u{6587}"
            let littleEndian = Data([0xFF, 0xFE, 0x2D, 0x4E, 0x87, 0x65])
            let bigEndian = Data([0xFE, 0xFF, 0x4E, 0x2D, 0x65, 0x87])

            try expectEqual(
                TextDecoder.decode(littleEndian),
                DecodedText(text: multibyteText, encoding: .utf16LittleEndian)
            )
            try expectEqual(
                TextDecoder.decode(bigEndian),
                DecodedText(text: multibyteText, encoding: .utf16BigEndian)
            )
        },
        TestCase("Text decoder reads GB18030 multibyte text") {
            let multibyteText = "\u{4E2D}\u{6587}"
            let decoded = try TextDecoder.decode(Data([0xD6, 0xD0, 0xCE, 0xC4]))
            try expectEqual(decoded, DecodedText(text: multibyteText, encoding: .gb18030))
        },
        TestCase("Text decoder rejects incomplete bytes") {
            try expectThrows(TextDecodingError.self) {
                _ = try TextDecoder.decode(Data([0x81]))
            }
        }
    ]
}
