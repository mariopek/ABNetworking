// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ABNetworking",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "ABNetworking",
            targets: ["ABNetworking"]),
    ],
    dependencies: [
        // No external dependencies
    ],
    targets: [
        .target(
            name: "ABNetworking",
            dependencies: []),
        .testTarget(
            name: "ABNetworkingTests",
            dependencies: ["ABNetworking"]),
    ]
)
