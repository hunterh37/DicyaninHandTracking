// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HandTracking",
    platforms: [
        .iOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "HandTracking",
            targets: ["HandTracking"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HandTracking",
            dependencies: []),
        .testTarget(
            name: "HandTrackingTests",
            dependencies: ["HandTracking"]),
    ]
) 