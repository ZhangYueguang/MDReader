import AppKit
import Foundation

func appIconTests() -> [TestCase] {
    [
        TestCase("Dock icon stays crisp across display scales") {
            let repositoryRoot = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let iconURL = repositoryRoot.appendingPathComponent("Assets/MDReader.icns")

            guard let image = NSImage(contentsOf: iconURL) else {
                throw TestFailure("Unable to read MDReader.icns")
            }

            for pixels in [64, 128, 256, 512, 1_024] {
                guard let icon = image.representations
                    .compactMap({ $0 as? NSBitmapImageRep })
                    .first(where: { $0.pixelsWide == pixels && $0.pixelsHigh == pixels }) else {
                    throw TestFailure("MDReader.icns must include a \(pixels) × \(pixels) representation")
                }

                var inkLuminance: [Double] = []
                var paperLuminance: [Double] = []
                for y in 0..<icon.pixelsHigh {
                    for x in 0..<icon.pixelsWide {
                        guard let color = icon.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                              color.alphaComponent > 0.99 else {
                            continue
                        }
                        let luminance = Double(
                            0.2126 * color.redComponent
                                + 0.7152 * color.greenComponent
                                + 0.0722 * color.blueComponent
                        )
                        if luminance < 0.3 {
                            inkLuminance.append(luminance)
                        } else if luminance > 0.9 {
                            paperLuminance.append(luminance)
                        }
                    }
                }

                guard !inkLuminance.isEmpty, !paperLuminance.isEmpty else {
                    throw TestFailure("\(pixels) px icon must contain both ink and paper pixels")
                }
                let inkMean = inkLuminance.reduce(0, +) / Double(inkLuminance.count)
                let paperMean = paperLuminance.reduce(0, +) / Double(paperLuminance.count)
                let paperVariance = paperLuminance.reduce(0) {
                    $0 + ($1 - paperMean) * ($1 - paperMean)
                } / Double(paperLuminance.count)

                guard inkMean < 0.23 else {
                    throw TestFailure("\(pixels) px icon ink is too washed out: mean luminance \(inkMean)")
                }
                guard paperVariance.squareRoot() < 0.005 else {
                    throw TestFailure("\(pixels) px icon paper texture is too noisy")
                }
            }
        },
        TestCase("Dock icon uses standard optical padding") {
            let repositoryRoot = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let iconURL = repositoryRoot.appendingPathComponent("Assets/MDReader.icns")

            guard let image = NSImage(contentsOf: iconURL),
                  let icon = image.representations
                    .compactMap({ $0 as? NSBitmapImageRep })
                    .first(where: { $0.pixelsWide == 128 && $0.pixelsHigh == 128 }) else {
                throw TestFailure("MDReader.icns must include a 128 × 128 representation")
            }

            var minimumX = icon.pixelsWide
            var maximumX = -1
            var minimumY = icon.pixelsHigh
            var maximumY = -1
            for y in 0..<icon.pixelsHigh {
                for x in 0..<icon.pixelsWide
                where (icon.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5 {
                    minimumX = min(minimumX, x)
                    maximumX = max(maximumX, x)
                    minimumY = min(minimumY, y)
                    maximumY = max(maximumY, y)
                }
            }

            guard maximumX >= minimumX, maximumY >= minimumY else {
                throw TestFailure("Dock icon must contain visible pixels")
            }
            let visibleWidthRatio = Double(maximumX - minimumX + 1) / Double(icon.pixelsWide)
            let visibleHeightRatio = Double(maximumY - minimumY + 1) / Double(icon.pixelsHigh)
            guard (0.78...0.84).contains(visibleWidthRatio),
                  (0.78...0.84).contains(visibleHeightRatio) else {
                throw TestFailure(
                    "Dock icon optical bounds are \(visibleWidthRatio) × \(visibleHeightRatio); expected about 0.81"
                )
            }
        }
    ]
}
