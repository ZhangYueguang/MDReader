import Foundation

struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

struct TestCase {
    let name: String
    let body: () throws -> Void

    init(_ name: String, body: @escaping () throws -> Void) {
        self.name = name
        self.body = body
    }
}

func expectEqual<T: Equatable>(
    _ actual: T,
    _ expected: T,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    guard actual == expected else {
        throw TestFailure(
            "Expected \(String(describing: expected)), got \(String(describing: actual)) at \(file):\(line)"
        )
    }
}

func expectThrows<E: Error>(
    _ errorType: E.Type,
    body: () throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    do {
        try body()
        throw TestFailure("Expected \(errorType) at \(file):\(line)")
    } catch is E {
        return
    }
}

@main
enum MDReaderTestRunner {
    static func main() throws {
        let tests = appMetadataTests()
            + appIconTests()
            + editorModeTests()
            + markdownDocumentTests()
            + markdownFormattingTests()
            + markdownSyntaxHighlighterTests()
            + textDecoderTests()
            + localResourceResolverTests()
            + readerResourceLocatorTests()
            + readerBridgeTests()
            + readerThemeTests()
        for test in tests {
            try test.body()
            print("PASS \(test.name)")
        }
        print("\(tests.count) tests passed")
    }
}
