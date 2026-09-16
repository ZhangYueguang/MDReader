import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Absolute image references are allowed, but must never expose arbitrary file bytes.
/// Validate the contents, not just the extension, before sending them to WebKit.
public struct LocalImageResource {
    public let data: Data
    public let mimeType: String

    public static func load(from url: URL) -> LocalImageResource? {
        guard url.isFileURL,
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              attributes[.type] as? FileAttributeType == .typeRegular,
              let size = attributes[.size] as? NSNumber,
              size.int64Value > 0, size.int64Value <= 64 * 1024 * 1024,
              let data = try? Data(contentsOf: url),
              data.count <= 64 * 1024 * 1024,
              let image = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(image) > 0,
              let typeIdentifier = CGImageSourceGetType(image),
              let type = UTType(typeIdentifier as String), type.conforms(to: .image),
              let mimeType = type.preferredMIMEType,
              let properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
              width.intValue > 0, height.intValue > 0 else {
            return nil
        }
        return LocalImageResource(data: data, mimeType: mimeType)
    }
}
