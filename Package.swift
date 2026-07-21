// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-speech-lanes",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "SpeechLanes",
            targets: ["SpeechLanes"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "SpeechLanes"
        ),
        .testTarget(
            name: "SpeechLanesTests",
            dependencies: ["SpeechLanes"],
            resources: [.copy("Fixtures")]
        )
    ]
)
