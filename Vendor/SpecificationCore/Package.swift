// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SpecificationCore",
    products: [
        .library(name: "SpecificationCore", targets: ["SpecificationCore"])
    ],
    targets: [
        .target(name: "SpecificationCore")
    ]
)
