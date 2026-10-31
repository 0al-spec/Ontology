import Foundation
import OntologyRules

/// Declaration families shown by the package visualizer.
public enum OntologyDiagramView: String, Sendable {
    case full
    case relations
}

/// Explicit view and local dependency inputs for a package diagram.
public struct OntologyDiagramOptions: Sendable {
    public let direction: OntologyDiagramDirection
    public let view: OntologyDiagramView
    public let imports: [OntologySourcePath]
    public let expandedTypes: [String]

    public init(
        direction: OntologyDiagramDirection = .leftToRight,
        view: OntologyDiagramView = .full,
        imports: [OntologySourcePath] = [],
        expandedTypes: [String] = []
    ) {
        self.direction = direction
        self.view = view
        self.imports = imports
        self.expandedTypes = expandedTypes
    }
}

extension OntologyCompiler {
    /// Projects a validated package and explicitly selected direct local imports.
    public func diagramDOT(path: OntologySourcePath, options: OntologyDiagramOptions) throws -> String {
        let projection = try diagramProjection(path: path, options: options)
        var diagram = PackageDiagram(ir: projection, view: options.view)
        return diagram.render(direction: options.direction)
    }

    /// Returns a declaration-oriented graph with source identities and logical YAML pointers.
    public func diagramProjection(
        path: OntologySourcePath, options: OntologyDiagramOptions = OntologyDiagramOptions()
    ) throws -> [String: Any] {
        diagnostics = []
        let decision = DiagramSelectionSpec().decide(DiagramSelectionContext(
            view: options.view.rawValue, hasImports: !options.imports.isEmpty, expandedTypes: options.expandedTypes
        ))
        guard decision == .valid else {
            throw OntologyCompilerError.invalidArgument(decision?.message ?? "Unknown diagram selection")
        }
        let root = try diagramIR(path: path)
        var imported = [DiagramImportedPackage]()
        for path in options.imports {
            let ir = try diagramIR(path: path)
            let namespace = try diagramImportNamespace(ir: ir, root: root)
            guard !imported.contains(where: { $0.namespace == namespace }) else {
                throw OntologyCompilerError.invalidArgument("Duplicate supplied import for namespace \(namespace)")
            }
            imported.append(try DiagramImportedPackage(namespace: namespace, ir: ir, root: root))
        }
        var projection = try options.view == .relations
            ? DiagramRelationsProjection(root: root, imported: imported).select(options.expandedTypes)
            : root
        if options.view == .relations {
            for section in ["protocols", "policies", "stateMachines"] { projection[section] = [JSONObject]() }
        }
        projection["schemaVersion"] = "ontology.diagram-projection/v1"
        projection["view"] = options.view.rawValue
        // Normalized IR's empty diagnostics field is not the result of checking
        // every source for warnings. Consumers should use the compiler report.
        projection.removeValue(forKey: "diagnostics")
        projection["sources"] = [diagramSource(root, alias: root["namespace"] as? String ?? "")]
            + imported.sorted { $0.namespace < $1.namespace }.map { diagramSource($0.ir, alias: $0.namespace) }
        return projection
    }

    /// Serializes the same projection used by DOT in a stable, portable JSON form.
    public func diagramJSON(
        path: OntologySourcePath, options: OntologyDiagramOptions = OntologyDiagramOptions()
    ) throws -> String {
        let graph = try diagramProjection(path: path, options: options)
        let data = try JSONSerialization.data(withJSONObject: graph, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        return String(decoding: data, as: UTF8.self) + "\n"
    }

    private func diagramIR(path: OntologySourcePath) throws -> JSONObject {
        let data: Data
        do {
            data = try Data(contentsOf: path.url)
        } catch {
            add("io.read", path.path, "Cannot read file: \(error.localizedDescription)")
            throw OntologyCompilerError.packageError(diagnostics)
        }
        guard let source = String(data: data, encoding: .utf8) else {
            add("io.read", path.path, "Cannot read file: invalid UTF-8")
            throw OntologyCompilerError.packageError(diagnostics)
        }
        guard let package = load(source: source, path: path.path) else { throw OntologyCompilerError.packageError(diagnostics) }
        validate(package)
        guard !hasErrors(diagnostics) else { throw OntologyCompilerError.packageError(diagnostics) }
        var ir = normalize(package)
        ir["sourceByteDigest"] = sha256(data)
        return diagramAttachSources(ir)
    }

    private func diagramImportNamespace(ir: JSONObject, root: JSONObject) throws -> String {
        let context = DiagramImportBindingContext(
            packageId: string(ir["id"]) ?? "", version: string(ir["version"]) ?? "",
            rootNamespace: string(root["namespace"]) ?? "", imports: diagramImports(root)
        )
        let identity = "\(context.packageId.rawValue)@\(context.version.rawValue)"
        switch DiagramImportBindingSpec().decide(context) {
        case .matched(let namespace): return namespace
        case .missing: throw OntologyCompilerError.invalidArgument("Supplied package \(identity) is not an exact direct import")
        case .ambiguous: throw OntologyCompilerError.invalidArgument("Ambiguous direct import binding for \(identity)")
        case .invalidNamespace, nil:
            throw OntologyCompilerError.invalidArgument("Invalid or shadowed namespace for \(identity)")
        }
    }
}

func diagramImports(_ ir: JSONObject) -> [DiagramImportDeclaration] {
    (ir["imports"] as? [JSONObject] ?? []).map {
        DiagramImportDeclaration(id: $0["id"] as? String ?? "", version: $0["version"] as? String ?? "",
                                 namespace: $0["namespace"] as? String ?? "")
    }
}

func diagramRangeReferences(_ value: Any?) -> [String] {
    if let ref = value as? String { return [ref] }
    return (value as? JSONObject)?["oneOf"] as? [String] ?? []
}
