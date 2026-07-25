// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "WiFiSnitch",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "WiFiSnitch", targets: ["WiFiSnitchAgent"]),
    .executable(name: "wifisnitch", targets: ["WiFiSnitch"]),
  ],
  dependencies: [
    .package(url: "https://github.com/gi8lino/easybar", from: "0.30.5"),
    .package(
      url: "https://github.com/gi8lino/SwiftTOMLEdit.git",
      exact: "0.0.4"
    ),

  ],
  targets: [
    .target(
      name: "WiFiSnitchShared",
      dependencies: [
        .product(name: "EasyBarShared", package: "easybar"),
        .product(name: "SwiftTOMLEdit", package: "swifttomledit"),
      ],
      path: "Source/WifiSnitchShared"
    ),
    .executableTarget(
      name: "WiFiSnitchAgent",
      dependencies: [
        "WiFiSnitchShared",
        .product(name: "EasyBarShared", package: "easybar"),
        .product(name: "EasyBarNetworkAgentCore", package: "easybar"),
      ],
      path: "Source/WifiSnitchAgent"
    ),
    .executableTarget(
      name: "WiFiSnitch",
      dependencies: [
        "WiFiSnitchShared",
        .product(name: "EasyBarShared", package: "easybar"),
      ],
      path: "Source/WifiSnitchCtl"
    ),
    .testTarget(
      name: "WiFiSnitchSharedTests",
      dependencies: [
        "WiFiSnitchShared"
      ],
      path: "Tests/WiFiSnitchSharedTests"
    ),
  ]
)
