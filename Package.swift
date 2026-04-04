// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "WiFiSnitch",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "wifisnitch-agent", targets: ["WiFiSnitchAgent"]),
    .executable(name: "wifisnitch", targets: ["WiFiSnitch"]),
  ],
  dependencies: [
    .package(path: "../easybar")
  ],
  targets: [
    .target(
      name: "WiFiSnitchShared",
      dependencies: [
        .product(name: "EasyBarShared", package: "easybar")
      ],
      path: "shared"
    ),
    .executableTarget(
      name: "WiFiSnitchAgent",
      dependencies: [
        "WiFiSnitchShared",
        .product(name: "EasyBarShared", package: "easybar"),
        .product(name: "EasyBarNetworkAgentCore", package: "easybar"),
      ],
      path: "agent"
    ),
    .executableTarget(
      name: "WiFiSnitch",
      dependencies: [
        "WiFiSnitchShared",
        .product(name: "EasyBarShared", package: "easybar"),
      ],
      path: "cli"
    ),
  ]
)
