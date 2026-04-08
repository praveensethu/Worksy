// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Worksy",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Worksy",
            path: "Sources/Worksy",
            resources: [.copy("Resources/Backgrounds")]
        ),
        .testTarget(
            name: "WorksyTests",
            dependencies: ["Worksy"],
            path: "Tests/WorksyTests"
        )
    ]
)
