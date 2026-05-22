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
    .package(
      url: "https://github.com/gi8lino/easybar.git", exact: "0.0.205"),
    .package(url: "https://github.com/LebJe/TOMLKit", from: "0.6.0"),
  ],
  targets: [
    .target(
      name: "WiFiSnitchShared",
      dependencies: [
        .product(name: "EasyBarShared", package: "easybar"),
        .product(name: "TOMLKit", package: "TOMLKit"),
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
  ]
)
