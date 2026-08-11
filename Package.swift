// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MDReader",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MDReaderKit", targets: ["MDReaderKit"]),
        .executable(name: "MDReader", targets: ["MDReaderApp"]),
        .executable(name: "MDReaderTests", targets: ["MDReaderTests"])
    ],
    targets: [
        .target(
            name: "MDReaderKit",
            resources: [
                .process("Resources"),
                .copy("GeneratedResources")
            ]
        ),
        .executableTarget(
            name: "MDReaderApp",
            dependencies: ["MDReaderKit"]
        ),
        .executableTarget(
            name: "MDReaderTests",
            dependencies: ["MDReaderKit"],
            path: "Tests/MDReaderTests"
        )
    ]
)
