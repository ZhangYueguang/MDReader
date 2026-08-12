import Foundation

func appMetadataTests() -> [TestCase] {
    [
        TestCase("Info.plist declares Markdown editor") {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let infoPlistURL = repositoryRoot.appendingPathComponent("Config/Info.plist")
        let data = try Data(contentsOf: infoPlistURL)
        let plistObject = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )
            guard let plist = plistObject as? [String: Any] else {
                throw TestFailure("Info.plist root must be a dictionary")
            }
            guard let documentTypes = plist["CFBundleDocumentTypes"] as? [[String: Any]],
                  let firstType = documentTypes.first else {
                throw TestFailure("Info.plist must declare a document type")
            }

            try expectEqual(
                plist["CFBundleIdentifier"] as? String,
                "com.frank.mdreader"
            )
            try expectEqual(plist["CFBundleDevelopmentRegion"] as? String, "en")
            try expectEqual(firstType["CFBundleTypeRole"] as? String, "Editor")
            try expectEqual(
                firstType["CFBundleTypeExtensions"] as? [String],
                ["md", "markdown"]
            )
        },
        TestCase("Info.plist declares the MDReader application icon") {
            let repositoryRoot = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let infoPlistURL = repositoryRoot.appendingPathComponent("Config/Info.plist")
            let data = try Data(contentsOf: infoPlistURL)
            let plistObject = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )
            guard let plist = plistObject as? [String: Any] else {
                throw TestFailure("Info.plist root must be a dictionary")
            }

            try expectEqual(plist["CFBundleIconFile"] as? String, "MDReader.icns")
        }
    ]
}
