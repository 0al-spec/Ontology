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
        let projection = try options.view == .relations
            ? DiagramRelationsProjection(root: root, imported: imported).select(options.expandedTypes)
            : root
        var diagram = PackageDiagram(ir: projection, view: options.view)
        return diagram.render(direction: options.direction)
    }

    private func diagramIR(path: OntologySourcePath) throws -> JSONObject {
        guard let package = load(path: path.path) else { throw OntologyCompilerError.packageError(diagnostics) }
        validate(package)
        guard !hasErrors(diagnostics) else { throw OntologyCompilerError.packageError(diagnostics) }
        return normalize(package)
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
