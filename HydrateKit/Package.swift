// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HydrateKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "HydrateKit",
            targets: ["HydrateKit"]
        ),
    ],
    targets: [
        .target(
            name: "HydrateKit",
            path: "Sources/HydrateKit"
        ),
        .testTarget(
            name: "HydrateKitTests",
            dependencies: ["HydrateKit"],
            path: "Tests/HydrateKitTests"
        ),
    ]
)
