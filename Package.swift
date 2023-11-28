// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScalesCore",
    platforms: [.macOS(.v12)],
     products: [
        .library(name: "ScalesCore", targets: ["ScalesCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift.git", branch: "master")
    ],
    targets: [
        .target(
            name: "ScalesCore",
            dependencies: [
                .product(name: "RealmSwift", package: "realm-swift"),
            ]),
        .testTarget(name: "ScalesCoreTests", dependencies: ["ScalesCore"])
    ],
    swiftLanguageVersions: [.v5]
)
