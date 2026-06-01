import Foundation

public final class OntologyCompiler {
    let apiVersion = "ontology.specgraph.io/v1alpha1"
    let kind = "DomainOntologyPackage"

    var diagnostics: [Diagnostic] = []

    public init() {}

    public func check(path: String) -> [Diagnostic] {
        diagnostics = []
        if let package = load(path: path) {
            validate(package)
        }
        return diagnostics.sorted {
            [$0.path, $0.code, $0.message].joined(separator: "\u{1f}") <
                [$1.path, $1.code, $1.message].joined(separator: "\u{1f}")
        }
    }

    public func compile(path: String, outDirectory: String) throws -> [Diagnostic] {
        diagnostics = []
        guard let package = load(path: path) else {
            return diagnostics
        }
        validate(package)
        if hasErrors(diagnostics) {
            return diagnostics
        }

        let ir = normalize(package)
        try emit(ir: ir, to: outDirectory)
        return diagnostics
    }

    public func validateSpecGraph(bindingPath: String, ontologyIRPath: String, outDirectory: String) throws -> (resolved: Int, gaps: Int) {
        let ir = try loadJSON(path: ontologyIRPath)
        let namespace = string(ir["namespace"]) ?? ""
        let index = conceptRefIndex(ir)
        let documents = try loadYAMLDocuments(path: bindingPath)
        let imports = collectOntologyImports(documents)
        let occurrences = collectRefOccurrences(documents, namespace: namespace)

        var resolvedRefs = [JSONObject]()
        var gaps = [JSONObject]()
        var seenResolved = Set<String>()
        var seenGaps = Set<String>()

        for occurrence in occurrences.sorted(by: { $0.ref < $1.ref }) {
            if let conceptRef = index[occurrence.ref] {
                if !seenResolved.contains(occurrence.ref) {
                    resolvedRefs.append(conceptRef)
                    seenResolved.insert(occurrence.ref)
                }
            } else if !seenGaps.contains(occurrence.ref) {
                gaps.append(ontologyGap(for: occurrence, ir: ir, ordinal: gaps.count + 1))
                seenGaps.insert(occurrence.ref)
            }
        }

        let outURL = URL(fileURLWithPath: outDirectory)
        try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
        try writeYAML([
            "apiVersion": "specgraph.io/v1alpha1",
            "kind": "ConceptRefSet",
            "metadata": [
                "ontology": string(ir["id"]) ?? "",
                "namespace": namespace,
                "version": string(ir["version"]) ?? ""
            ],
            "spec": [
                "refs": resolvedRefs
            ]
        ], to: outURL.appendingPathComponent("concept-refs.yaml"))

        try writeYAML(lockfile(imports: imports, ir: ir, index: index), to: outURL.appendingPathComponent("ontology.lock.yaml"))

        try writeYAML([
            "apiVersion": "specgraph.io/v1alpha1",
            "kind": "OntologyGapSet",
            "metadata": [
                "source": bindingPath
            ],
            "spec": [
                "gaps": gaps
            ]
        ], to: outURL.appendingPathComponent("ontology-gaps.yaml"))

        return (resolvedRefs.count, gaps.count)
    }

    public func diffPackages(from fromPath: String, to toPath: String, outPath: String) throws -> [Diagnostic] {
        diagnostics = []
        guard let fromPackage = load(path: fromPath), let toPackage = load(path: toPath) else {
            return diagnostics
        }
        validate(fromPackage)
        validate(toPackage)
        if hasErrors(diagnostics) {
            return diagnostics
        }

        let fromIR = normalize(fromPackage)
        let toIR = normalize(toPackage)
        let report = compatibilityReport(fromIR: fromIR, toIR: toIR)
        try writeYAML(report, to: URL(fileURLWithPath: outPath))
        return diagnostics
    }

    public func hasErrors(_ diagnostics: [Diagnostic]) -> Bool {
        diagnostics.contains { $0.severity == "error" }
    }

    public func printDiagnostics(_ diagnostics: [Diagnostic]) {
        for diagnostic in diagnostics {
            var line = "\(diagnostic.severity) \(diagnostic.code) \(diagnostic.path): \(diagnostic.message)"
            if let hint = diagnostic.hint {
                line += " Hint: \(hint)"
            }
            print(line)
        }
    }
}
