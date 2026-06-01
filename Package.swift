// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Ontology",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ontologyc", targets: ["OntologyC"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", exact: "6.2.2")
    ],
    targets: [
        .executableTarget(
            name: "OntologyC",
            dependencies: ["Yams"]
        )
    ]
)
