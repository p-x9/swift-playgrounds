// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SwiftPackages",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SwiftPackages",
            targets: [
                "SwiftPackages"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/p-x9/SDCALayer.git", branch: "main")
    ],
    targets: [
        .target(
            name: "SwiftPackages",
            dependencies: [
                .product(name: "SDCALayer", package: "SDCALayer")
            ]
        )
    ]
)
