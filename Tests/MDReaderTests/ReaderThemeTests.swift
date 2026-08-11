import AppKit
import Foundation
import MDReaderKit

func readerThemeTests() -> [TestCase] {
    [
        TestCase("Reader paper color follows Aqua and Dark Aqua") {
            let light = try resolvedPaperComponents(for: .aqua)
            let dark = try resolvedPaperComponents(for: .darkAqua)

            try expectComponents(light, equalTo: (1, 1, 1, 1))
            try expectComponents(
                dark,
                equalTo: (28 / 255, 27 / 255, 25 / 255, 1)
            )
        }
    ]
}

private func resolvedPaperComponents(
    for appearanceName: NSAppearance.Name
) throws -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    guard let appearance = NSAppearance(named: appearanceName) else {
        throw TestFailure("Missing appearance \(appearanceName.rawValue)")
    }

    var resolvedColor: NSColor?
    appearance.performAsCurrentDrawingAppearance {
        resolvedColor = ReaderTheme.paperColor.usingColorSpace(.sRGB)
    }
    guard let resolvedColor else {
        throw TestFailure("Reader paper color is not convertible to sRGB")
    }
    return (
        resolvedColor.redComponent,
        resolvedColor.greenComponent,
        resolvedColor.blueComponent,
        resolvedColor.alphaComponent
    )
}

private func expectComponents(
    _ actual: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat),
    equalTo expected: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat),
    tolerance: CGFloat = 0.001
) throws {
    let differences = [
        abs(actual.red - expected.red),
        abs(actual.green - expected.green),
        abs(actual.blue - expected.blue),
        abs(actual.alpha - expected.alpha)
    ]
    guard differences.allSatisfy({ $0 <= tolerance }) else {
        throw TestFailure("Expected RGBA \(expected), got \(actual)")
    }
}
