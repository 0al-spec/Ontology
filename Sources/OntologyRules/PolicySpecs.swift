import SpecificationCore

/// Validates policy enforceability modes that the ontology runtime model understands.
public struct AllowedPolicyEnforceabilitySpec: Specification {
    public typealias T = PolicyEnforceability

    private let allowed = Set(["design", "runtime", "manual", "audit"])

    public init() {}

    public func isSatisfiedBy(_ candidate: PolicyEnforceability) -> Bool {
        allowed.contains(candidate.rawValue)
    }
}
