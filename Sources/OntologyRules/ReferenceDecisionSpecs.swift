import SpecificationCore

/// Decision emitted after checking concept reference syntax and resolution source.
public enum ConceptRefResolutionDecision: Equatable {
    case local
    case imported
    case unresolved
    case invalidSyntax

    public var resolves: Bool {
        self == .local || self == .imported
    }
}

/// Decides whether a concept reference is local, imported, unresolved, or syntactically invalid.
public struct ConceptRefResolutionDecisionSpec: DecisionSpec {
    public typealias Context = ConceptRefResolutionContext
    public typealias Result = ConceptRefResolutionDecision

    private let syntax = OntologyConceptRefPatternSpec()
    private let local = LocalConceptRefSpec()
    private let imported = ImportedConceptRefSpec()

    public init() {}

    public func decide(_ context: ConceptRefResolutionContext) -> ConceptRefResolutionDecision? {
        guard syntax.isSatisfiedBy(OntologyConceptReferenceLiteral(rawValue: context.ref)) else {
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
