import SpecificationCore

/// Validates that a package declares the ontology API version supported by this compiler.
public struct ExpectedOntologyApiVersionSpec: Specification {
    public typealias T = OntologyApiVersion

    public init() {}

    public func isSatisfiedBy(_ candidate: OntologyApiVersion) -> Bool {
        candidate.rawValue == "ontology.specgraph.io/v1alpha1"
    }
}

/// Validates that a package declares the expected domain ontology package kind.
public struct ExpectedDomainOntologyPackageKindSpec: Specification {
    public typealias T = OntologyPackageKind

    public init() {}

    public func isSatisfiedBy(_ candidate: OntologyPackageKind) -> Bool {
        candidate.rawValue == "DomainOntologyPackage"
    }
}
