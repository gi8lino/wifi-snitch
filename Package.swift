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
    .package(url: "https://github.com/gi8lino/easybar.git", branch: "main")
  ],
  targets: [
    .target(
      name: "WiFiSnitchShared",
      path: "shared"
    ),
    .executableTarget(
      name: "WiFiSnitchAgent",
      dependencies: [
        "WiFiSnitchShared",
        .product(name: "EasyBarShared", package: "easybar"),
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
