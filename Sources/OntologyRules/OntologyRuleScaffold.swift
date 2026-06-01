import SpecificationCore

public struct NonEmptyOntologyStringSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        !candidate.isEmpty
    }
}

public enum OntologyRulesScaffold {
    public static func nonEmptyStringSpec() -> NonEmptyOntologyStringSpec {
        NonEmptyOntologyStringSpec()
    }
}
