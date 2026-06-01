import SpecificationCore

public struct AllowedPolicyEnforceabilitySpec: Specification {
    public typealias T = String

    private let allowed = Set(["design", "runtime", "manual", "audit"])

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        allowed.contains(candidate)
    }
}
