import SpecificationCore

/// Parsed shape of a relation `range` field.
public enum RelationRangeShapeDecision: Equatable {
    case scalarRef(String)
    case oneOfRefs([String])
    case invalid
}

/// Decides whether a relation range is a scalar reference, a `oneOf` reference list, or invalid.
public struct RelationRangeShapeDecisionSpec: DecisionSpec {
    public typealias Context = Any
    public typealias Result = RelationRangeShapeDecision

    public init() {}

    public func decide(_ context: Any) -> RelationRangeShapeDecision? {
        if let ref = context as? String {
            return .scalarRef(ref)
        }
        if let object = context as? [String: Any],
           let oneOf = object["oneOf"] as? [Any] {
            return .oneOfRefs(oneOf.compactMap { $0 as? String })
        }
        return .invalid
    }
}
