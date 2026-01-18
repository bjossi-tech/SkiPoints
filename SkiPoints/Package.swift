// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SkiPoints",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "SkiPoints",
            targets: ["SkiPoints"]
        ),
    ],
    targets: [
        .target(
            name: "SkiPoints",
            path: "Sources/SkiPoints"
        ),
        .testTarget(
            name: "SkiPointsTests",
            dependencies: ["SkiPoints"],
            path: "Tests/SkiPointsTests"
        ),
    ]
)
