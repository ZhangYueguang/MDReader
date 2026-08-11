#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: generate-dmg-background.swift <output.png>\n", stderr)
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let canvasSize = NSSize(width: 660, height: 400)
let image = NSImage(size: canvasSize)
guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: .alphaNonpremultiplied,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
    fputs("Unable to create the DMG background canvas.\n", stderr)
    exit(1)
}

bitmap.size = canvasSize
image.addRepresentation(bitmap)
image.lockFocus()

NSColor(calibratedRed: 0.975, green: 0.967, blue: 0.940, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

let titleFont = NSFont(name: "Iowan Old Style Roman", size: 28)
    ?? NSFont(name: "Baskerville", size: 28)
    ?? NSFont.systemFont(ofSize: 28, weight: .regular)
let bodyFont = NSFont.systemFont(ofSize: 14, weight: .regular)
let titleColor = NSColor(calibratedWhite: 0.14, alpha: 1)
let secondaryColor = NSColor(calibratedWhite: 0.34, alpha: 1)
let accentColor = NSColor(calibratedRed: 0.19, green: 0.36, blue: 0.43, alpha: 1)

func drawCentered(_ text: String, y: CGFloat, font: NSFont, color: NSColor) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
    ]
    let size = text.size(withAttributes: attributes)
    text.draw(
        at: NSPoint(x: (canvasSize.width - size.width) / 2, y: y),
        withAttributes: attributes
    )
}

drawCentered("MDReader", y: 327, font: titleFont, color: titleColor)
drawCentered("Drag MDReader to Applications", y: 299, font: bodyFont, color: secondaryColor)

let arrow = NSBezierPath()
arrow.lineWidth = 2
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.move(to: NSPoint(x: 275, y: 177))
arrow.line(to: NSPoint(x: 385, y: 177))
arrow.move(to: NSPoint(x: 373, y: 188))
arrow.line(to: NSPoint(x: 385, y: 177))
arrow.line(to: NSPoint(x: 373, y: 166))
accentColor.withAlphaComponent(0.72).setStroke()
arrow.stroke()

let divider = NSBezierPath()
divider.lineWidth = 1
divider.move(to: NSPoint(x: 90, y: 272))
divider.line(to: NSPoint(x: 570, y: 272))
NSColor(calibratedWhite: 0.18, alpha: 0.10).setStroke()
divider.stroke()

image.unlockFocus()

guard
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to render the DMG background.\n", stderr)
    exit(1)
}

do {
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try pngData.write(to: outputURL, options: .atomic)
} catch {
    fputs("Unable to write the DMG background: \(error.localizedDescription)\n", stderr)
    exit(1)
}
