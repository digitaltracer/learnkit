// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "LearnKitKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LearnKitKit",
            targets: ["LearnKitKit"]
        ),
    ],
    targets: [
        .target(
            name: "LearnKitKit"
        ),
        .testTarget(
            name: "LearnKitKitTests",
            dependencies: ["LearnKitKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
