// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Kalirova",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "KalirovaCore", targets: ["KalirovaCore"])
    ],
    targets: [
        .target(
            name: "KalirovaCore",
            path: "Kalirova/Core"
        ),
        .testTarget(
            name: "KalirovaCoreTests",
            dependencies: ["KalirovaCore"],
            path: "Tests/KalirovaCoreTests"
        )
    ]
)

