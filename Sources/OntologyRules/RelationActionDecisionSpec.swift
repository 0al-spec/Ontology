import SpecificationCore

public enum RelationActionResolution: Equatable {
    case action, wrongKind, unresolved, cyclicAncestry
}

/// Resolves an action through local class ancestry to a verified foundation export.
/// An external import without an export catalog cannot certify that ancestry.
public struct RelationActionDecisionSpec: DecisionSpec {
    private let packageNamespace: String
    private let classBases: [String: String]
    private let foundations: [String: FoundationExports]

    public init(packageNamespace: String, classBases: [String: String], foundations: [String: FoundationExports]) {
        self.packageNamespace = packageNamespace
        self.classBases = classBases
        self.foundations = foundations
    }

    public func decide(_ reference: String) -> RelationActionResolution? {
        var current = reference
        var visited = Set<String>()
        while OntologyConceptRefPatternSpec().isSatisfiedBy(.init(rawValue: current)) {
            let name = refName(current)
            if let namespace = refNamespace(current), namespace != packageNamespace {
                guard let catalog = foundations[namespace], catalog.classes.contains(name) else { return .unresolved }
                return name == "Action" ? .action : .wrongKind
            }
            guard let base = classBases[name] else { return .unresolved }
            guard visited.insert(name).inserted else { return .cyclicAncestry }
            current = base
        }
        return .unresolved
    }
}
