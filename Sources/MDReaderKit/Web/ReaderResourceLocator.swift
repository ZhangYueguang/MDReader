import Foundation

public enum ReaderResourceLocator {
    private static let resourceBundleName = "MDReader_MDReaderKit.bundle"

    public static func packagedResources(
        appResourceURL: URL?,
        fileManager: FileManager = .default
    ) -> URL? {
        guard let appResourceURL else { return nil }
        let candidate = appResourceURL
            .appendingPathComponent(resourceBundleName, isDirectory: true)
            .appendingPathComponent("GeneratedResources", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }
        return candidate
    }

    static func resourcesForCurrentProcess() -> URL {
        if let packaged = packagedResources(appResourceURL: Bundle.main.resourceURL) {
            return packaged
        }
        guard let moduleResources = Bundle.module.resourceURL else {
            fatalError("MDReader resources are missing.")
        }
        return moduleResources.appendingPathComponent("GeneratedResources", isDirectory: true)
    }
}
