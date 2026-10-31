import SpecificationCore

/// One direct import declaration available to a diagram's root package.
public struct DiagramImportDeclaration: Equatable {
    public let id: OntologyPackageId
    public let version: OntologySemanticVersion
    public let namespace: OntologyNamespace

    public init(id: String, version: String, namespace: String) {
        self.id = OntologyPackageId(rawValue: id)
        self.version = OntologySemanticVersion(rawValue: version)
        self.namespace = OntologyNamespace(rawValue: namespace)
    }
}

/// Identity of a supplied local dependency and the root's declared import scope.
public struct DiagramImportBindingContext {
    public let packageId: OntologyPackageId
    public let version: OntologySemanticVersion
    public let rootNamespace: OntologyNamespace
    public let imports: [DiagramImportDeclaration]

    public init(packageId: String, version: String, rootNamespace: String, imports: [DiagramImportDeclaration]) {
        self.packageId = OntologyPackageId(rawValue: packageId)
        self.version = OntologySemanticVersion(rawValue: version)
        self.rootNamespace = OntologyNamespace(rawValue: rootNamespace)
        self.imports = imports
    }
}

/// Outcome of binding an explicitly supplied package to a direct root import.
public enum DiagramImportBindingDecision: Equatable {
    case matched(namespace: String)
    case missing
    case ambiguous
    case invalidNamespace
}

/// Binds exact package identity/version to a unique, non-root diagram namespace.
public struct DiagramImportBindingSpec: DecisionSpec {
    public typealias Context = DiagramImportBindingContext
    public typealias Result = DiagramImportBindingDecision

    public init() {}

    public func decide(_ context: Context) -> Result? {
        let matches = context.imports.filter { $0.id == context.packageId && $0.version == context.version }
        guard let match = matches.first else { return .missing }
        guard matches.count == 1 else { return .ambiguous }
        guard match.namespace != context.rootNamespace,
              OntologyNamespacePatternSpec().isSatisfiedBy(match.namespace) else {
            return .invalidNamespace
        }
        guard context.imports.filter({ $0.namespace == match.namespace }).count == 1 else { return .ambiguous }
        return .matched(namespace: match.namespace.rawValue)
    }
}

/// Ensures declared aliases cannot shadow a supplied package's own namespace or each other.
public struct DiagramImportScopeSpec: Specification {
    public typealias T = DiagramImportBindingContext

    public init() {}

    public func isSatisfiedBy(_ context: T) -> Bool {
        let aliases = context.imports.map(\.namespace).filter { !$0.rawValue.isEmpty }
        return !aliases.contains(context.rootNamespace) && Set(aliases).count == aliases.count
    }
}
