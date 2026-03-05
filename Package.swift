// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "LiquidSpeedBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "LiquidSpeedBar",
            targets: ["LiquidSpeedBar"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LiquidSpeedBar"
        )
    ]
)
