import SpecificationCore

/// Checks whether a relation range is encoded as one scalar concept reference.
public struct ScalarRelationRangeSpec: Specification {
    public typealias T = Any

    public init() {}

    public func isSatisfiedBy(_ candidate: Any) -> Bool {
        candidate is String
    }
}

/// Checks whether a relation range is encoded as an object containing a `oneOf` list.
public struct OneOfRelationRangeSpec: Specification {
    public typealias T = Any

    public init() {}

    public func isSatisfiedBy(_ candidate: Any) -> Bool {
        guard let object = candidate as? [String: Any] else { return false }
        return object["oneOf"] is [Any]
    }
}
