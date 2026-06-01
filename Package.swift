// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Ontology",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ontologyc", targets: ["OntologyC"]),
        .library(name: "OntologyCompiler", targets: ["OntologyCompiler"]),
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
        .target(
            name: "OntologyCompiler",
            dependencies: ["Yams", "OntologyRules"]
        ),
        .executableTarget(
            name: "OntologyC",
            dependencies: ["OntologyCompiler"]
        ),
        .testTarget(
            name: "OntologyRulesTests",
            dependencies: ["OntologyRules"]
        ),
        .testTarget(
            name: "OntologyCompilerTests",
            dependencies: ["OntologyCompiler"]
        )
    ]
)
