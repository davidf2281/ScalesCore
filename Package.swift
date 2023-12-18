// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScalesCore",
    platforms: [.macOS(.v13)],
     products: [
        .library(name: "ScalesCore", targets: ["ScalesCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ScalesCore",
            dependencies: []),
        .testTarget(name: "ScalesCoreTests", dependencies: ["ScalesCore"])
    ],
    swiftLanguageVersions: [.v5]
)
