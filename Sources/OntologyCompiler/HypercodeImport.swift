import Foundation
import OntologyRules

private struct HypercodeDraftContext {
    let path: OntologySourcePath
    let packageId: OntologyPackageId
    let namespace: OntologyNamespace
    let version: OntologySemanticVersion
    let nodeTypes: [String]
    let symbols: [String]
    let rootSymbol: String
    let reviewCommand: String
}

private let supportedHypercodeIRVersions = Set([
    "hypercode.ir/v1",
    "hypercode.ir/v2"
])

extension OntologyCompiler {
    public func importHypercode(
        path: OntologySourcePath,
        outPath: OntologyOutputPath,
        packageId: OntologyPackageId,
        namespace: OntologyNamespace,
        version: OntologySemanticVersion
    ) throws -> [Diagnostic] {
        diagnostics = []
        let ir = try loadHypercodeIR(path: path)
        let package: JSONObject
        if string(ir["version"]) == "hypercode.ir/v2",
           let root = firstHypercodeRoot(ir),
           isHypercodeOntologyPackageRoot(root) {
            package = try hypercodeOntologyPackage(root, sourcePath: path.path)
        } else {
            let nodeTypes = collectHypercodeNodeTypes(ir)
            guard !nodeTypes.isEmpty else {
                throw OntologyCompilerError.invalidArgument("Hypercode IR has no nodes: \(path.path)")
            }

            let symbols = uniqueSymbols(for: nodeTypes)
            let rootSymbol = symbols.first ?? "ImportedHypercodeRoot"
            let reviewCommand = uniqueGeneratedSymbol("ReviewGeneratedDraft", existing: Set(symbols))
            package = hypercodeDraftPackage(HypercodeDraftContext(
                path: path,
                packageId: packageId,
                namespace: namespace,
                version: version,
                nodeTypes: nodeTypes,
                symbols: symbols,
                rootSymbol: rootSymbol,
                reviewCommand: reviewCommand
            ))
        }

        if let parent = outPath.url.deletingLastPathComponentIfPresent {
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        try writeYAML(package, to: outPath.url)
        return diagnostics
    }

    private func hypercodeDraftPackage(_ context: HypercodeDraftContext) -> JSONObject {
        [
            "apiVersion": apiVersion,
            "kind": kind,
            "metadata": hypercodeDraftMetadata(
                path: context.path,
                packageId: context.packageId,
                namespace: context.namespace,
                version: context.version
            ),
            "spec": hypercodeDraftSpec(
                nodeTypes: context.nodeTypes,
                symbols: context.symbols,
                rootSymbol: context.rootSymbol,
                reviewCommand: context.reviewCommand
            )
        ]
    }

    private func hypercodeDraftMetadata(
        path: OntologySourcePath,
        packageId: OntologyPackageId,
        namespace: OntologyNamespace,
        version: OntologySemanticVersion
    ) -> JSONObject {
        [
            "id": packageId.rawValue,
            "namespace": namespace.rawValue,
            "version": version.rawValue,
            "publisher": "ontologyc import-hypercode",
            "source": path.path,
            "approvalStatus": "draft"
        ]
    }

    private func hypercodeDraftSpec(
        nodeTypes: [String],
        symbols: [String],
        rootSymbol: String,
        reviewCommand: String
    ) -> JSONObject {
        [
            "imports": hypercodeDraftImports(),
            "classes": hypercodeDraftClasses(nodeTypes: nodeTypes, symbols: symbols, rootSymbol: rootSymbol, reviewCommand: reviewCommand),
            "protocols": JSONObject(),
            "relations": hypercodeDraftRelations(symbols: symbols, rootSymbol: rootSymbol),
            "policies": hypercodeDraftPolicies(rootSymbol: rootSymbol),
            "stateMachines": hypercodeDraftStateMachines(reviewCommand: reviewCommand),
            "compatibility": hypercodeDraftCompatibility()
        ]
    }

    private func hypercodeDraftImports() -> [JSONObject] {
        [
            [
                "id": "specgraph.foundation",
                "namespace": "sg",
                "version": "0.1.0"
            ]
        ]
    }

    private func hypercodeDraftClasses(
        nodeTypes: [String],
        symbols: [String],
        rootSymbol: String,
        reviewCommand: String
    ) -> JSONObject {
        var classes = JSONObject()
        for (index, symbol) in symbols.enumerated() {
            classes[symbol] = [
                "extends": "sg:DomainEntity",
                "description": "Draft ontology concept imported from Hypercode node type \(nodeTypes[index]).",
                "central": symbol == rootSymbol
            ]
        }
        classes[reviewCommand] = [
            "extends": "sg:Command",
            "description": "Synthetic review command for the generated Hypercode import draft."
        ]
        return classes
    }

    private func hypercodeDraftRelations(symbols: [String], rootSymbol: String) -> JSONObject {
        let rangeSymbols = containmentRangeSymbols(symbols: symbols, rootSymbol: rootSymbol)
        return [
            "contains": [
                "domain": rootSymbol,
                "range": ["oneOf": rangeSymbols],
                "cardinality": [
                    "min": 0,
                    "max": "*"
                ],
                "description": "Draft structural containment relation inferred from Hypercode parent-child structure."
            ]
        ]
    }

    private func containmentRangeSymbols(symbols: [String], rootSymbol: String) -> [String] {
        let nonRoot = symbols.filter { $0 != rootSymbol }.sorted()
        return nonRoot.isEmpty ? [rootSymbol] : nonRoot
    }

    private func hypercodeDraftPolicies(rootSymbol: String) -> JSONObject {
        [
            "GeneratedDraftRequiresReview": [
                "extends": "sg:Policy",
                "enforceability": "manual",
                "appliesTo": [rootSymbol],
                "text": "Hypercode imports are ontology drafts and require review before approval."
            ]
        ]
    }

    private func hypercodeDraftStateMachines(reviewCommand: String) -> JSONObject {
        [
            "GeneratedDraftLifecycle": [
                "states": [
                    "draft",
                    "reviewed"
                ],
                "transitions": [
                    [
                        "from": "draft",
                        "to": "reviewed",
                        "command": reviewCommand
                    ]
                ]
            ]
        ]
    }

    private func hypercodeDraftCompatibility() -> JSONObject {
        [
            "patch": [
                "allowed": ["add description"]
            ],
            "minor": [
                "allowed": ["add class", "add relation"]
            ],
            "major": [
                "requires": ["remove class", "remove relation"]
            ]
        ]
    }

    private func loadHypercodeIR(path: OntologySourcePath) throws -> JSONObject {
        let data: Data
        do {
            data = try Data(contentsOf: path.url)
        } catch {
            throw OntologyCompilerError.invalidArgument("Cannot read Hypercode IR \(path.path): \(error.localizedDescription)")
        }
        guard let root = try JSONSerialization.jsonObject(with: data) as? JSONObject else {
            throw OntologyCompilerError.invalidArgument("Hypercode IR root must be a JSON object: \(path.path)")
        }
        guard let version = string(root["version"]),
              supportedHypercodeIRVersions.contains(version) else {
            throw OntologyCompilerError.invalidArgument(
                "Expected Hypercode IR version hypercode.ir/v1 or hypercode.ir/v2 in \(path.path)"
            )
        }
        guard let nodes = root["nodes"] as? [Any] else {
            throw OntologyCompilerError.invalidArgument("Hypercode IR must contain a nodes array: \(path.path)")
        }
        guard
            let firstRoot = nodes.first as? JSONObject,
            let rootType = string(firstRoot["type"]),
            !rootType.isEmpty
        else {
            throw OntologyCompilerError.invalidArgument("Hypercode IR root node must have a non-empty type: \(path.path)")
        }
        return root
    }

    private func collectHypercodeNodeTypes(_ ir: JSONObject) -> [String] {
        guard let nodes = ir["nodes"] as? [Any] else { return [] }
        var ordered: [String] = []
        var seen = Set<String>()

        func visit(_ node: Any) {
            guard let object = node as? JSONObject else { return }
            if let type = string(object["type"]), !type.isEmpty, !seen.contains(type) {
                ordered.append(type)
                seen.insert(type)
            }
            if let children = object["children"] as? [Any] {
                for child in children {
                    visit(child)
                }
            }
        }

        for node in nodes {
            visit(node)
        }
        return ordered
    }

    private func firstHypercodeRoot(_ ir: JSONObject) -> JSONObject? {
        (ir["nodes"] as? [Any])?.first as? JSONObject
    }

    private func uniqueSymbols(for rawValues: [String]) -> [String] {
        var seen = Set<String>()
        return rawValues.map { raw in
            let base = symbolName(from: raw, fallback: "ImportedHypercodeConcept")
            let unique = uniqueGeneratedSymbol(base, existing: seen)
            seen.insert(unique)
            return unique
        }
    }

    private func uniqueGeneratedSymbol(_ base: String, existing: Set<String>) -> String {
        var candidate = base
        var suffix = 2
        while existing.contains(candidate) {
            candidate = "\(base)\(suffix)"
            suffix += 1
        }
        return candidate
    }

    private func symbolName(from raw: String, fallback: String) -> String {
        let words = raw
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !$0.isEmpty }
        let joined = words.map { word in
            word.prefix(1).uppercased() + word.dropFirst()
        }.joined()
        let candidate = joined.isEmpty ? fallback : joined
        if candidate.first?.isLetter == true {
            return candidate
        }
        return "Concept\(candidate)"
    }
}

private extension URL {
    var deletingLastPathComponentIfPresent: URL? {
        let parent = deletingLastPathComponent()
        return parent.path == path ? nil : parent
    }
}
