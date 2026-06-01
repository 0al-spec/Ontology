// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Ontology",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ontologyc", targets: ["OntologyC"]),
        .library(name: "OntologyRules", targets: ["OntologyRules"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", exact: "6.2.2"),
        .package(url: "https://github.com/SoundBlaster/SpecificationCore", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "OntologyRules",
            dependencies: ["SpecificationCore"]
        ),
        .executableTarget(
            name: "OntologyC",
            dependencies: ["Yams"]
        ),
        .testTarget(
            name: "OntologyRulesTests",
            dependencies: ["OntologyRules"]
        ),
        .testTarget(
            name: "OntologyCompilerTests",
            dependencies: []
        )
    ]
)
