import SpecificationCore

/// Parsed shape of a relation `range` field.
public enum RelationRangeShapeDecision: Equatable {
    case scalarRef(String)
    case oneOfRefs([String])
    case invalid
}

/// Source shape with one slot per original list member. A nil member was not a string.
public enum RelationRangeSourceShape: Equatable {
    case scalarRef(String)
    case oneOfMembers([String?])
    case invalid
}

/// Decides whether a relation range is a scalar reference, a `oneOf` reference list, or invalid.
public struct RelationRangeShapeDecisionSpec: DecisionSpec {
    public typealias Context = Any
    public typealias Result = RelationRangeShapeDecision

    public init() {}

    public func decide(_ context: Any) -> RelationRangeShapeDecision? {
        switch sourceShape(of: context) {
        case .scalarRef(let ref): .scalarRef(ref)
        case .oneOfMembers(let members): .oneOfRefs(members.compactMap { $0 })
        case .invalid: .invalid
        }
    }

    /// Use the unfiltered source slots when producing diagnostics for authors.
    public func sourceShape(of context: Any) -> RelationRangeSourceShape {
        if let ref = context as? String {
            return .scalarRef(ref)
        }
        if let object = context as? [String: Any],
           let oneOf = object["oneOf"] as? [Any] {
            return .oneOfMembers(oneOf.map { $0 as? String })
        }
        return .invalid
    }
}
