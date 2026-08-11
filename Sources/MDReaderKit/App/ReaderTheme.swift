import AppKit

public enum ReaderTheme {
    public static let paperColor = NSColor(
        name: NSColor.Name("com.frank.mdreader.paper")
    ) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(
                srgbRed: 28 / 255,
                green: 27 / 255,
                blue: 25 / 255,
                alpha: 1
            )
        }
        return .white
    }
}
