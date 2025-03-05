// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "itest-scanner",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "iTestScanner", targets: ["iTestScanner"]),
    .executable(name: "itest-scanner", targets: ["iTestScannerCLI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/indexstore-db.git", revision: "swift-6.0.3-RELEASE"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
  ],
  targets: [
    .target(
      name: "iTestScanner",
      dependencies: [
        .product(name: "IndexStoreDB", package: "indexstore-db"),
      ]
    ),
    .executableTarget(
      name: "iTestScannerCLI",
      dependencies: [
        "iTestScanner",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(name: "iTestScannerTests", dependencies: ["iTestScanner"]),
  ]
)
