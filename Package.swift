// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HealthTrackAI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "HealthTrackAICore", targets: ["HealthTrackAICore"])
    ],
    targets: [
        .target(
            name: "HealthTrackAICore",
            path: "HealthTrackAI/Core"
        ),
        .testTarget(
            name: "HealthTrackAICoreTests",
            dependencies: ["HealthTrackAICore"],
            path: "Tests/HealthTrackAICoreTests"
        )
    ]
)

