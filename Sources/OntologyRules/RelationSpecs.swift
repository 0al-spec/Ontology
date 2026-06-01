import SpecificationCore

public struct ScalarRelationRangeSpec: Specification {
    public typealias T = Any

    public init() {}

    public func isSatisfiedBy(_ candidate: Any) -> Bool {
        candidate is String
    }
}

public struct OneOfRelationRangeSpec: Specification {
    public typealias T = Any

    public init() {}

    public func isSatisfiedBy(_ candidate: Any) -> Bool {
        guard let object = candidate as? [String: Any] else { return false }
        return object["oneOf"] is [Any]
    }
}
