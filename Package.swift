// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Ontology",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ontologyc", targets: ["OntologyC"]),
        .executable(name: "ontologyviz", targets: ["OntologyViz"]),
        .library(name: "OntologyCompiler", targets: ["OntologyCompiler"]),
        .library(name: "OntologyRules", targets: ["OntologyRules"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", exact: "6.2.2"),
        .package(url: "https://github.com/apple/swift-crypto.git", exact: "4.3.1"),
        .package(path: "Vendor/SpecificationCore"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "OntologyRules",
            dependencies: ["SpecificationCore"]
        ),
        .target(
            name: "OntologyCompiler",
            dependencies: [
                "Yams", "OntologyRules",
                .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux]))
            ]
        ),
        .executableTarget(
            name: "OntologyC",
            dependencies: ["OntologyCompiler", "OntologyRules"]
        ),
        .executableTarget(
            name: "OntologyViz",
            dependencies: ["OntologyCompiler"]
        ),
        .testTarget(
            name: "OntologyRulesTests",
            dependencies: ["OntologyRules"]
        ),
        .testTarget(
            name: "OntologyCompilerTests",
            dependencies: [
                "OntologyCompiler", "OntologyRules",
                .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux]))
            ]
        )
    ]
)
