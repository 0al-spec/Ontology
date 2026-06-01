import SpecificationCore

public struct ExpectedOntologyApiVersionSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        candidate == "ontology.specgraph.io/v1alpha1"
    }
}

public struct ExpectedDomainOntologyPackageKindSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        candidate == "DomainOntologyPackage"
    }
}
