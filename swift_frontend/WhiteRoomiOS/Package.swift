// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftFrontendShared",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftFrontendShared",
            targets: ["SwiftFrontendShared"]),
    ],
    dependencies: [
        // SnapshotTesting for visual regression tests
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.17.0"
        ),
    ],
    targets: [
        .target(
            name: "SwiftFrontendShared",
            dependencies: [],
            path: "../SwiftFrontendShared",
            resources: [
                // Add any resource files here
            ]
        ),
        .testTarget(
            name: "SwiftFrontendSharedTests",
            dependencies: [
                "SwiftFrontendShared",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "../SwiftFrontendSharedTests"
        ),
    ]
)
