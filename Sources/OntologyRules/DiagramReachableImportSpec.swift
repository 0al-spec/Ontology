import SpecificationCore

/// Versioned package identity, independent of any package-local namespace alias.
public struct DiagramPackageIdentity: Hashable, Sendable {
    public let id: OntologyPackageId
    public let version: OntologySemanticVersion

    public init(id: String, version: String) {
        self.id = OntologyPackageId(rawValue: id)
        self.version = OntologySemanticVersion(rawValue: version)
    }
}

/// An explicitly supplied package and the dependency identities reachable from the root.
public struct DiagramReachableImportContext {
    public let supplied: DiagramPackageIdentity
    public let reachable: Set<DiagramPackageIdentity>

    public init(supplied: DiagramPackageIdentity, reachable: Set<DiagramPackageIdentity>) {
        self.supplied = supplied
        self.reachable = reachable
    }
}

/// Accepts only an exact identity and version found in the supplied dependency graph.
public struct DiagramReachableImportSpec: Specification {
    public typealias T = DiagramReachableImportContext

    public init() {}

    public func isSatisfiedBy(_ context: DiagramReachableImportContext) -> Bool {
        context.reachable.contains(context.supplied)
    }
}
