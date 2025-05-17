// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DicyaninHandTracking",
    platforms: [
        .iOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "DicyaninHandTracking",
            targets: ["DicyaninHandTracking"]),
    ],
    dependencies: [
        .package(path: "DicyaninARKitSession")
    ],
    targets: [
        .target(
            name: "DicyaninHandTracking",
            dependencies: ["DicyaninARKitSession"]),
        .testTarget(
            name: "HandTrackingTests",
            dependencies: ["DicyaninHandTracking"]),
    ]
) 
