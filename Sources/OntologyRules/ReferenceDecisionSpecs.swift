import SpecificationCore

public enum ConceptRefResolutionDecision: Equatable {
    case local
    case imported
    case unresolved
    case invalidSyntax

    public var resolves: Bool {
        self == .local || self == .imported
    }
}

public struct ConceptRefResolutionDecisionSpec: DecisionSpec {
    public typealias Context = ConceptRefResolutionContext
    public typealias Result = ConceptRefResolutionDecision

    private let syntax = OntologyConceptRefPatternSpec()
    private let local = LocalConceptRefSpec()
    private let imported = ImportedConceptRefSpec()

    public init() {}

    public func decide(_ context: ConceptRefResolutionContext) -> ConceptRefResolutionDecision? {
        guard syntax.isSatisfiedBy(context.ref) else {
            return .invalidSyntax
        }
        if local.isSatisfiedBy(context) {
            return .local
        }
        if imported.isSatisfiedBy(context) {
            return .imported
        }
        return .unresolved
    }
}
