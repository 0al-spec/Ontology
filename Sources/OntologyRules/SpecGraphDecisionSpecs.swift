import SpecificationCore

public typealias OntologyJSONObject = [String: Any]

public struct SpecGraphRefDecisionContext {
    public let ref: String
    public let conceptIndex: [String: OntologyJSONObject]

    public init(ref: String, conceptIndex: [String: OntologyJSONObject]) {
        self.ref = ref
        self.conceptIndex = conceptIndex
    }
}

public enum SpecGraphRefDecision {
    case resolved(OntologyJSONObject)
    case gap
}

public struct SpecGraphRefDecisionSpec: DecisionSpec {
    public typealias Context = SpecGraphRefDecisionContext
    public typealias Result = SpecGraphRefDecision

    public init() {}

    public func decide(_ context: SpecGraphRefDecisionContext) -> SpecGraphRefDecision? {
        if let conceptRef = context.conceptIndex[context.ref] {
            return .resolved(conceptRef)
        }
        return .gap
    }
}
