// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FloGraph",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FloGraph",
            targets: ["FloGraph"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url:"https://github.com/kk-0129/FloBox.git", from: "1.0.0"),
        //.package(path: "../FloBox")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FloGraph",
            dependencies: [
                .product(name: "FloBox", package: "FloBox")
            ]),
        .testTarget(
            name: "FloGraphTests",
            dependencies: [
                "FloGraph",
                .product(name: "FloBox", package:"FloBox")
            ]),
    ]
)
