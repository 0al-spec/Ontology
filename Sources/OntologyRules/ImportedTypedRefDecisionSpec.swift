import SpecificationCore

/// Inputs for resolving a typed reference against supplied package exports.
public struct ImportedTypedRefContext: Equatable, Sendable {
    public let reference: String
    public let localNames: Set<String>
    public let localNamespace: String
    public let declaredAliases: Set<String>
    public let classesByAlias: [String: Set<String>]
    public let namespacesByAlias: [String: String]
    public let identitiesByAlias: [String: String]

    public init(reference: String, localNames: Set<String>, localNamespace: String,
                declaredAliases: Set<String>, classesByAlias: [String: Set<String>],
                namespacesByAlias: [String: String], identitiesByAlias: [String: String]) {
        self.reference = reference
        self.localNames = localNames
        self.localNamespace = localNamespace
        self.declaredAliases = declaredAliases
        self.classesByAlias = classesByAlias
        self.namespacesByAlias = namespacesByAlias
        self.identitiesByAlias = identitiesByAlias
    }
}

/// Resolution outcome for an instance reference's declared target class.
public enum ImportedTypedRefDecision: Equatable {
    case local
    case imported
    case namespaceConflict
    case unresolved
}

/// Requires an exact supplied class and rejects ambiguous runtime type names.
public struct ImportedTypedRefDecisionSpec: DecisionSpec {
    public typealias Context = ImportedTypedRefContext
    public typealias Result = ImportedTypedRefDecision

    public init() {}

    public func decide(_ context: Context) -> Result? {
        let local = ConceptRefResolutionContext(ref: context.reference, localNames: context.localNames,
                                                packageNamespace: context.localNamespace, importNamespaces: [])
        if ConceptRefResolutionDecisionSpec().decide(local) == .local { return .local }
        guard OntologyConceptRefPatternSpec().isSatisfiedBy(OntologyConceptReferenceLiteral(rawValue: context.reference)),
              let alias = refNamespace(context.reference), context.declaredAliases.contains(alias),
              context.classesByAlias[alias]?.contains(refName(context.reference)) == true,
              let canonical = context.namespacesByAlias[alias] else { return .unresolved }
        let name = refName(context.reference)
        let duplicate = context.namespacesByAlias.contains { otherAlias, namespace in
            otherAlias != alias && namespace == canonical &&
                context.identitiesByAlias[otherAlias] != context.identitiesByAlias[alias] &&
                context.classesByAlias[otherAlias]?.contains(name) == true
        }
        if (canonical == context.localNamespace && context.localNames.contains(name)) || duplicate {
            return .namespaceConflict
        }
        return .imported
    }
}
