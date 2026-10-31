import SpecificationCore

/// Checks whether a relation range is encoded as one scalar concept reference.
public struct ScalarRelationRangeSpec: Specification {
    public typealias T = Any

    public init() {}

    public func isSatisfiedBy(_ candidate: Any) -> Bool {
        if case .scalarRef = RelationRangeShapeDecisionSpec().sourceShape(of: candidate) { return true }
        return false
    }
}

/// Checks whether a relation range is encoded as an object containing a `oneOf` list.
public struct OneOfRelationRangeSpec: Specification {
    public typealias T = Any

    public init() {}

    public func isSatisfiedBy(_ candidate: Any) -> Bool {
        if case .oneOfMembers = RelationRangeShapeDecisionSpec().sourceShape(of: candidate) { return true }
        return false
    }
}
