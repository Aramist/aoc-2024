// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "aoc_2024",
    dependencies: [
        .package(
            url:"https://github.com/yeatse/opencv-spm.git",
            from: "4.10.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "aoc_2024",
            dependencies: [
                .product(name: "OpenCV", package: "opencv-spm")
            ]),
    ]
)
