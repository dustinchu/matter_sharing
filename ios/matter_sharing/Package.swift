// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "matter_sharing",
    platforms: [.iOS("16.1")],
    products: [
        .library(name: "matter-sharing", targets: ["matter_sharing"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "matter_sharing",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            path: "Sources/matter_sharing"
        ),
    ]
)
