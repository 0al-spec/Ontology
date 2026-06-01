import SpecificationCore

public enum CompatibilityChangeKind: Equatable {
    case removedClass
    case removedRelation
    case relationDomainChanged
    case relationRangeChanged
}

public struct CompatibilityChangeContext: Equatable {
    public let kind: CompatibilityChangeKind
    public let namespace: String
    public let symbolId: String
    public let beforeComparable: String
    public let afterComparable: String

    public init(
        kind: CompatibilityChangeKind,
        namespace: String,
        symbolId: String,
        beforeComparable: String = "",
        afterComparable: String = ""
    ) {
        self.kind = kind
        self.namespace = namespace
        self.symbolId = symbolId
        self.beforeComparable = beforeComparable
        self.afterComparable = afterComparable
    }
}

public enum CompatibilityChangeDecision: Equatable {
    case compatible
    case breaking(String)
}

public struct CompatibilityChangeDecisionSpec: DecisionSpec {
    public typealias Context = CompatibilityChangeContext
    public typealias Result = CompatibilityChangeDecision

    public init() {}

    public func decide(_ context: CompatibilityChangeContext) -> CompatibilityChangeDecision? {
        switch context.kind {
        case .removedClass:
            return .breaking("remove class \(context.namespace):\(context.symbolId)")
        case .removedRelation:
            return .breaking("remove relation \(context.namespace):\(context.symbolId)")
        case .relationDomainChanged:
            return context.beforeComparable == context.afterComparable
                ? .compatible
                : .breaking("change relation domain \(context.namespace):\(context.symbolId)")
        case .relationRangeChanged:
            return context.beforeComparable == context.afterComparable
                ? .compatible
                : .breaking("change relation range \(context.namespace):\(context.symbolId)")
        }
    }
}
