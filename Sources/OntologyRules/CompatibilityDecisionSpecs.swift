import SpecificationCore

/// Kinds of ontology changes that participate in compatibility decisions.
public enum CompatibilityChangeKind: Equatable {
    case removedClass
    case removedRelation
    case classLayerChanged
    case relationLayerChanged
    case relationDomainChanged
    case relationRangeChanged
    case classRequiredFieldAdded
    case classFieldRemoved
    case classFieldTypeChanged
    case classFieldRequirednessChanged
}

/// Inputs required to classify one ontology symbol change against a previous package version.
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

/// Compatibility outcome for a single ontology change.
public enum CompatibilityChangeDecision: Equatable {
    case compatible
    case breaking(String)
}

/// Decides whether a tracked ontology change is compatible or breaking.
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
        case .classLayerChanged, .relationLayerChanged:
            return .compatible
        case .relationDomainChanged:
            return context.beforeComparable == context.afterComparable
                ? .compatible
                : .breaking("change relation domain \(context.namespace):\(context.symbolId)")
        case .relationRangeChanged:
            return context.beforeComparable == context.afterComparable
                ? .compatible
                : .breaking("change relation range \(context.namespace):\(context.symbolId)")
        case .classRequiredFieldAdded:
            return .breaking("add required field \(context.namespace):\(context.symbolId)")
        case .classFieldRemoved:
            return .breaking("remove field \(context.namespace):\(context.symbolId)")
        case .classFieldTypeChanged:
            return context.beforeComparable == context.afterComparable
                ? .compatible
                : .breaking("change field type \(context.namespace):\(context.symbolId)")
        case .classFieldRequirednessChanged:
            if context.beforeComparable == context.afterComparable {
                return .compatible
            }
            return context.beforeComparable == "false" && context.afterComparable == "true"
                ? .breaking("make field required \(context.namespace):\(context.symbolId)")
                : .compatible
        }
    }
}
