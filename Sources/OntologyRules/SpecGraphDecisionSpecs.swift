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

public struct OntologyReferenceSetResolutionContext {
    public let references: [String]
    public let conceptIndex: [String: OntologyJSONObject]

    public init(references: [String], conceptIndex: [String: OntologyJSONObject]) {
        self.references = references
        self.conceptIndex = conceptIndex
    }
}

public struct OntologyReferenceSetResolution: Equatable {
    public let resolved: [String]
    public let gaps: [String]

    public var allResolved: Bool {
        gaps.isEmpty
    }

    public init(resolved: [String], gaps: [String]) {
        self.resolved = resolved
        self.gaps = gaps
    }
}

public struct OntologyReferenceSetResolutionSpec: DecisionSpec {
    public typealias Context = OntologyReferenceSetResolutionContext
    public typealias Result = OntologyReferenceSetResolution

    private let referenceDecisionSpec = SpecGraphRefDecisionSpec()

    public init() {}

    public func decide(_ context: OntologyReferenceSetResolutionContext) -> OntologyReferenceSetResolution? {
        var resolved = [String]()
        var gaps = [String]()

        for reference in context.references {
            switch referenceDecisionSpec.decide(SpecGraphRefDecisionContext(
                ref: reference,
                conceptIndex: context.conceptIndex
            )) {
            case .resolved:
                resolved.append(reference)
            case .gap:
                gaps.append(reference)
            case nil:
                return nil
            }
        }

        return OntologyReferenceSetResolution(resolved: resolved, gaps: gaps)
    }
}
