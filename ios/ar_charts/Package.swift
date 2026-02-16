// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ar_charts",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(
            name: "ar-charts",
            targets: ["ar_charts"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ChartsOrg/Charts.git", from: "5.1.0"),
    ],
    targets: [
        .target(
            name: "ar_charts",
            dependencies: [
                .product(name: "DGCharts", package: "Charts"),
            ]
        ),
    ]
)
