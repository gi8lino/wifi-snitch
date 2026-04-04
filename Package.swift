// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "WiFiSnitch",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "WiFiSnitchAgent", targets: ["WiFiSnitchAgent"]),
    .executable(name: "wifisnitchctl", targets: ["wifisnitchctl"]),
  ],
  dependencies: [
    .package(path: "../easybar")
  ],
  targets: [
    .target(
      name: "WiFiSnitchShared",
      dependencies: [
        .product(name: "EasyBarShared", package: "easybar"),
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
      name: "wifisnitchctl",
      dependencies: [
        "WiFiSnitchShared",
        .product(name: "EasyBarShared", package: "easybar"),
      ],
      path: "cli"
    ),
  ]
)
