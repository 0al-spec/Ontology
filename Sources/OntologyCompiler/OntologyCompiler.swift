import Foundation
import OntologyRules

/// Errors raised by compiler workflows when arguments, packages, or registry payloads cannot be processed.
public enum OntologyCompilerError: Error, CustomStringConvertible {
    case invalidArgument(String)
    case packageError([Diagnostic])

    public var description: String {
        switch self {
        case .invalidArgument(let msg): return msg
        case .packageError(let diags):
            return diags.map { "\($0.severity) \($0.code): \($0.message)" }.joined(separator: "\n")
        }
    }
}

/// Orchestrates ontology package loading, validation, normalization, generation, registry operations, and SpecGraph validation.
public final class OntologyCompiler {
    let apiVersion = "ontology.specgraph.io/v1alpha1"
    let kind = "DomainOntologyPackage"

    var diagnostics: [Diagnostic] = []

    /// Creates a compiler instance with an empty diagnostic buffer.
    public init() {}

    /// Parses and validates one ontology package, returning sorted diagnostics without writing output files.
    public func check(path: OntologySourcePath) -> [Diagnostic] {
        diagnostics = []
        if let package = load(path: path.path) {
            validate(package)
        }
        return diagnostics.sorted {
            [$0.path, $0.code, $0.message].joined(separator: "\u{1f}") <
                [$1.path, $1.code, $1.message].joined(separator: "\u{1f}")
        }
    }

    /// Validates one ontology package and emits normalized IR plus generated TypeScript artifacts.
    public func compile(path: OntologySourcePath, outDirectory: OntologyOutputDirectory) throws -> [Diagnostic] {
        diagnostics = []
        guard let package = load(path: path.path) else {
            return diagnostics
        }
        validate(package)
        if hasErrors(diagnostics) {
            return diagnostics
        }

        let ir = normalize(package)
        try emit(ir: ir, to: outDirectory.path)
        return diagnostics
    }

    /// Resolves ontology references from SpecGraph binding documents and writes resolved refs, gaps, and a lockfile.
    public func validateSpecGraph(
        bindingPath: OntologySourcePath,
        ontologyIRPath: OntologySourcePath,
        outDirectory: OntologyOutputDirectory,
        sourceURI: String = "",
        sourceRef: String = ""
    ) throws -> (resolved: Int, gaps: Int) {
        let ir = try loadJSON(path: ontologyIRPath.path)
        let namespace = string(ir["namespace"]) ?? ""
        let index = conceptRefIndex(ir)
        let documents = try loadYAMLDocuments(path: bindingPath.path)
        let imports = collectOntologyImports(documents)
        let occurrences = collectRefOccurrences(documents, namespace: namespace)

        var resolvedRefs = [JSONObject]()
        var gaps = [JSONObject]()
        var seenResolved = Set<String>()
        var seenGaps = Set<String>()

        for occurrence in occurrences.sorted(by: { $0.ref < $1.ref }) {
            let decision = SpecGraphRefDecisionSpec().decide(
                SpecGraphRefDecisionContext(ref: occurrence.ref, conceptIndex: index)
            )
            switch decision {
            case .resolved(let conceptRef):
                if !seenResolved.contains(occurrence.ref) {
                    resolvedRefs.append(conceptRef)
                    seenResolved.insert(occurrence.ref)
                }
            case .gap, nil:
                if !seenGaps.contains(occurrence.ref) {
                    gaps.append(ontologyGap(for: occurrence, ir: ir, ordinal: gaps.count + 1))
                    seenGaps.insert(occurrence.ref)
                }
            }
        }

        let outURL = outDirectory.url
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
                "source": bindingPath.path
            ],
            "spec": [
                "gaps": gaps
            ]
        ], to: outURL.appendingPathComponent("ontology-gaps.yaml"))

        try writeYAML(
            ontologycAdapterReport(
                OntologycAdapterReportContext(
                    bindingPath: bindingPath.path,
                    ontologyIRPath: ontologyIRPath.path,
                    ir: ir,
                    resolvedCount: resolvedRefs.count,
                    gapCount: gaps.count,
                    sourceURI: sourceURI,
                    sourceRef: sourceRef
                )
            ),
            to: outURL.appendingPathComponent("ontologyc-adapter-report.yaml")
        )

        return (resolvedRefs.count, gaps.count)
    }

    /// Compares two ontology packages and writes a compatibility report to `outPath`.
    public func diffPackages(
        from fromPath: OntologySourcePath,
        to toPath: OntologySourcePath,
        outPath: OntologyOutputPath
    ) throws -> [Diagnostic] {
        diagnostics = []
        guard let fromPackage = load(path: fromPath.path), let toPackage = load(path: toPath.path) else {
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
        try writeYAML(report, to: outPath.url)
        return diagnostics
    }

    /// Publishes a validated ontology package IR to a registry endpoint.
    public func publishPackage(
        path: OntologySourcePath,
        registry: RegistryBaseURL,
        token: String?,
        channel: OntologyPublishChannel = .candidate,
        governanceDecisionPath: OntologySourcePath? = nil,
        goldenReportPath: OntologySourcePath? = nil
    ) throws -> (diagnostics: [Diagnostic], packageRef: OntologyPackageReference) {
        try publishPackage(
            request: RegistryPublishRequest(
                path: path,
                registry: registry,
                token: token,
                channel: channel,
                governanceDecisionPath: governanceDecisionPath,
                goldenReportPath: goldenReportPath
            ),
            put: { url, data, token in try RegistryClient().put(url: url, body: data, token: token) }
        )
    }

    struct RegistryPublishRequest {
        let path: OntologySourcePath
        let registry: RegistryBaseURL
        let token: String?
        let channel: OntologyPublishChannel
        let governanceDecisionPath: OntologySourcePath?
        let goldenReportPath: OntologySourcePath?
    }

    func publishPackage(
        request: RegistryPublishRequest,
        put: (URL, Data, String?) throws -> Void
    ) throws -> (diagnostics: [Diagnostic], packageRef: OntologyPackageReference) {
        diagnostics = []
        guard let package = load(path: request.path.path) else {
            throw OntologyCompilerError.packageError(diagnostics)
        }
        validate(package)
        if hasErrors(diagnostics) {
            throw OntologyCompilerError.packageError(diagnostics)
        }
        try validatePublishGovernanceGate(
            channel: request.channel,
            decisionPath: request.governanceDecisionPath,
            packagePath: request.path,
            goldenReportPath: request.goldenReportPath
        )
        let ir = normalize(package)
        let id = string(ir["id"]) ?? ""
        let version = string(ir["version"]) ?? ""
        let packageRef = OntologyPackageReference(id: id, version: version)
        if request.registry.isFileRegistry {
            try publishLocalPackage(ir: ir, ref: packageRef, registry: request.registry, channel: request.channel)
            return (diagnostics: diagnostics, packageRef: packageRef)
        }

        let urlString = "\(request.registry.absoluteString)/ontologies/\(id)/\(version)"
        guard let url = URL(string: urlString) else {
            add("registry.url.invalid", "publish", "Invalid registry URL: \(urlString)")
            throw OntologyCompilerError.packageError(diagnostics)
        }
        let data = try JSONSerialization.data(
            withJSONObject: ir,
            options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        )
        try put(url, data, request.token)
        return (diagnostics: diagnostics, packageRef: packageRef)
    }

    private func validatePublishGovernanceGate(
        channel: OntologyPublishChannel,
        decisionPath: OntologySourcePath?,
        packagePath: OntologySourcePath,
        goldenReportPath: OntologySourcePath?
    ) throws {
        guard channel == .trusted || decisionPath != nil || goldenReportPath != nil else { return }
        guard let decisionPath else {
            add(
                "registry.publish.governanceDecision.required",
                "publish.--decision",
                "--channel trusted and --golden-report require --decision"
            )
            throw OntologyCompilerError.packageError(diagnostics)
        }

        let result = try validateGovernanceDecision(
            decisionPath: decisionPath,
            packagePath: packagePath,
            goldenReportPath: goldenReportPath,
            outPath: nil
        )
        diagnostics = result.diagnostics
        if channel == .trusted, result.decisionState != "approved" {
            add(
                "registry.publish.governanceDecision.approved.required",
                "decision.spec.decision.state",
                "trusted publication requires an approved governance decision"
            )
        }
        if hasErrors(diagnostics) {
            throw OntologyCompilerError.packageError(diagnostics)
        }
    }

    /// Pulls a normalized ontology package IR from a registry and writes it into `outDirectory`.
    public func pullPackage(
        ref: OntologyPackageReference,
        registry: RegistryBaseURL,
        token: String?,
        outDirectory: OntologyOutputDirectory
    ) throws {
        let data = try pullPackageData(ref: ref, registry: registry, token: token)
        let filename = "\(ref.id.replacingOccurrences(of: ".", with: "-"))-\(ref.version).normalized.json"
        let outURL = outDirectory.url
        try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
        try data.write(to: outURL.appendingPathComponent(filename))
    }

    /// Checks whether a local package remains compatible with a registry package reference.
    public func compatCheckPackage(
        path: OntologySourcePath,
        against ref: OntologyPackageReference,
        registry: RegistryBaseURL,
        token: String?,
        outPath: OntologyOutputPath?
    ) throws -> Bool {
        diagnostics = []
        guard let toPackage = load(path: path.path) else {
            throw OntologyCompilerError.packageError(diagnostics)
        }
        validate(toPackage)
        if hasErrors(diagnostics) {
            throw OntologyCompilerError.packageError(diagnostics)
        }
        let toIR = normalize(toPackage)

        let irData = try pullPackageData(ref: ref, registry: registry, token: token)
        guard let fromIR = try JSONSerialization.jsonObject(with: irData) as? JSONObject else {
            throw OntologyCompilerError.invalidArgument("Registry IR is not valid JSON for \(ref.rawValue)")
        }
        let report = compatibilityReport(fromIR: fromIR, toIR: toIR)
        if let outPath {
            try writeYAML(report, to: outPath.url)
        }
        return (report["result"] as? JSONObject)?["compatible"] as? Bool ?? false
    }

    private func pullPackageData(ref: OntologyPackageReference, registry: RegistryBaseURL, token: String?) throws -> Data {
        if registry.isFileRegistry {
            return try pullLocalPackageData(ref: ref, registry: registry)
        }
        let urlString = "\(registry.absoluteString)/ontologies/\(ref.id)/\(ref.version)"
        guard let url = URL(string: urlString) else {
            throw OntologyCompilerError.invalidArgument("Invalid registry URL: \(urlString)")
        }
        return try RegistryClient().get(url: url, token: token)
    }

    /// Returns whether a diagnostic collection contains at least one error severity.
    public func hasErrors(_ diagnostics: [Diagnostic]) -> Bool {
        diagnostics.contains { $0.severity == "error" }
    }

    /// Prints diagnostics using the stable command-line text format.
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
