// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WiFiSnitch",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "WiFiSnitchAgent", targets: ["WiFiSnitchAgent"]),
        .executable(name: "wifisnitchctl", targets: ["wifisnitchctl"]),
    ],
    targets: [
        .target(
            name: "WiFiSnitchShared",
            path: "shared"
        ),
        .executableTarget(
            name: "WiFiSnitchAgent",
            dependencies: ["WiFiSnitchShared"],
            path: "agent"
        ),
        .executableTarget(
            name: "wifisnitchctl",
            dependencies: ["WiFiSnitchShared"],
            path: "cli"
        ),
    ]
)
