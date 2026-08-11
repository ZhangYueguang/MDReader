#!/usr/bin/env swift

import AppKit
import Foundation

private struct IconRepresentation {
    let filename: String
    let pixels: Int
}

private enum IconGenerationError: Error, CustomStringConvertible {
    case invalidArguments
    case unreadableSource(URL)
    case bitmapCreation(Int)
    case pngEncoding(Int)
    case iconutilFailed(Int32)

    var description: String {
        switch self {
        case .invalidArguments:
            return "Usage: generate-app-icon.swift <source.png> <output.icns>"
        case let .unreadableSource(url):
            return "Unable to read source icon: \(url.path)"
        case let .bitmapCreation(pixels):
            return "Unable to create \(pixels) × \(pixels) icon bitmap"
        case let .pngEncoding(pixels):
            return "Unable to encode \(pixels) × \(pixels) icon PNG"
        case let .iconutilFailed(status):
            return "iconutil failed with exit status \(status)"
        }
    }
}

private let representations = [
    IconRepresentation(filename: "icon_16x16.png", pixels: 16),
    IconRepresentation(filename: "icon_16x16@2x.png", pixels: 32),
    IconRepresentation(filename: "icon_32x32.png", pixels: 32),
    IconRepresentation(filename: "icon_32x32@2x.png", pixels: 64),
    IconRepresentation(filename: "icon_128x128.png", pixels: 128),
    IconRepresentation(filename: "icon_128x128@2x.png", pixels: 256),
    IconRepresentation(filename: "icon_256x256.png", pixels: 256),
    IconRepresentation(filename: "icon_256x256@2x.png", pixels: 512),
    IconRepresentation(filename: "icon_512x512.png", pixels: 512),
    IconRepresentation(filename: "icon_512x512@2x.png", pixels: 1024)
]

private func makeBitmap(pixels: Int) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: .alphaNonpremultiplied,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw IconGenerationError.bitmapCreation(pixels)
    }
    return bitmap
}

private func makeCrispRepresentation(
    source: NSBitmapImageRep,
    pixels: Int
) throws -> Data {
    let result = try makeBitmap(pixels: pixels)
    let contentPixels = max(1, Int((CGFloat(pixels) * 0.82).rounded()))
    let contentInset = (pixels - contentPixels) / 2
    let transparent = NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 0)
    let paper = (red: CGFloat(0xF3) / 255, green: CGFloat(0xF0) / 255, blue: CGFloat(0xE8) / 255)
    let ink = (red: CGFloat(0x25) / 255, green: CGFloat(0x2A) / 255, blue: CGFloat(0x2E) / 255)

    for y in 0..<pixels {
        for x in 0..<pixels {
            result.setColor(transparent, atX: x, y: y)
        }
    }

    for y in 0..<contentPixels {
        for x in 0..<contentPixels {
            let sourceXStart = x * source.pixelsWide / contentPixels
            let sourceXEnd = max(sourceXStart + 1, (x + 1) * source.pixelsWide / contentPixels)
            let sourceYStart = y * source.pixelsHigh / contentPixels
            let sourceYEnd = max(sourceYStart + 1, (y + 1) * source.pixelsHigh / contentPixels)
            var shapeCoverage: CGFloat = 0
            var inkCoverage: CGFloat = 0
            var sampleCount: CGFloat = 0

            for sourceY in sourceYStart..<sourceYEnd {
                for sourceX in sourceXStart..<sourceXEnd {
                    guard let color = source.colorAt(x: sourceX, y: sourceY)?.usingColorSpace(.deviceRGB) else {
                        continue
                    }
                    let luminance = 0.2126 * color.redComponent
                        + 0.7152 * color.greenComponent
                        + 0.0722 * color.blueComponent
                    shapeCoverage += color.alphaComponent
                    if color.alphaComponent > 0.5, luminance < 0.55 {
                        inkCoverage += 1
                    }
                    sampleCount += 1
                }
            }

            let alpha = shapeCoverage / sampleCount
            let inkMix = inkCoverage / sampleCount
            result.setColor(
                NSColor(
                    deviceRed: paper.red + (ink.red - paper.red) * inkMix,
                    green: paper.green + (ink.green - paper.green) * inkMix,
                    blue: paper.blue + (ink.blue - paper.blue) * inkMix,
                    alpha: alpha
                ),
                atX: x + contentInset,
                y: y + contentInset
            )
        }
    }

    guard let data = result.representation(using: .png, properties: [:]) else {
        throw IconGenerationError.pngEncoding(pixels)
    }
    return data
}

private func run() throws {
    guard CommandLine.arguments.count == 3 else {
        throw IconGenerationError.invalidArguments
    }

    let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
    let outputURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
    guard let sourceImage = NSImage(contentsOf: sourceURL),
          let sourceData = sourceImage.tiffRepresentation,
          let source = NSBitmapImageRep(data: sourceData) else {
        throw IconGenerationError.unreadableSource(sourceURL)
    }

    let fileManager = FileManager.default
    let workspace = fileManager.temporaryDirectory
        .appendingPathComponent("MDReaderIcon-\(UUID().uuidString)", isDirectory: true)
    let iconsetURL = workspace.appendingPathComponent("MDReader.iconset", isDirectory: true)
    try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: workspace) }

    var renderedData: [Int: Data] = [:]
    for representation in representations {
        let data: Data
        if let existing = renderedData[representation.pixels] {
            data = existing
        } else {
            data = try makeCrispRepresentation(source: source, pixels: representation.pixels)
            renderedData[representation.pixels] = data
        }
        try data.write(to: iconsetURL.appendingPathComponent(representation.filename), options: .atomic)
    }

    let iconutil = Process()
    iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    iconutil.arguments = [
        "--convert", "icns",
        iconsetURL.path,
        "--output", outputURL.path
    ]
    try iconutil.run()
    iconutil.waitUntilExit()
    guard iconutil.terminationStatus == 0 else {
        throw IconGenerationError.iconutilFailed(iconutil.terminationStatus)
    }
}

do {
    try run()
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
