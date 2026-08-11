import Foundation
import MDReaderKit

func readerResourceLocatorTests() -> [TestCase] {
    [
        TestCase("Reader resources prefer the packaged application bundle") {
            let fileManager = FileManager.default
            let temporaryRoot = fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            let appResources = temporaryRoot
                .appendingPathComponent("MDReader.app/Contents/Resources", isDirectory: true)
            let generatedResources = appResources
                .appendingPathComponent("MDReader_MDReaderKit.bundle", isDirectory: true)
                .appendingPathComponent("GeneratedResources", isDirectory: true)
            try fileManager.createDirectory(
                at: generatedResources,
                withIntermediateDirectories: true
            )
            defer { try? fileManager.removeItem(at: temporaryRoot) }

            try expectEqual(
                ReaderResourceLocator.packagedResources(
                    appResourceURL: appResources,
                    fileManager: fileManager
                ),
                generatedResources
            )
        },
        TestCase("Reader resources reject an incomplete application bundle") {
            let missingResources = URL(
                fileURLWithPath: "/tmp/missing-mdreader-app/Contents/Resources",
                isDirectory: true
            )

            try expectEqual(
                ReaderResourceLocator.packagedResources(
                    appResourceURL: missingResources
                ),
                nil
            )
        }
    ]
}
