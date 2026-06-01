import SpecificationCore

public struct DeclaredStateSpec: Specification {
    public typealias T = StateMembershipContext

    public init() {}

    public func isSatisfiedBy(_ candidate: StateMembershipContext) -> Bool {
        candidate.states.contains(candidate.state)
    }
}
