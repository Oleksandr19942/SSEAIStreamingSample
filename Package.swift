// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SSEAIStreamingSample",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SSEAIStreamingSample",
            targets: ["SSEAIStreamingSample"]
        ),
    ],
    targets: [
        .target(
            name: "SSEAIStreamingSample"
        ),
        .testTarget(
            name: "SSEAIStreamingSampleTests",
            dependencies: ["SSEAIStreamingSample"]
        ),
    ]
)
