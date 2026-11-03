import OntologyRules

extension OntologyCompiler {
    func validateRelationAction(_ value: Any, path: String, spec: RelationActionDecisionSpec) {
        guard let ref = string(value) else {
            add("relation.action.type", path, "Relation action must be a reference string")
            return
        }
        switch spec.decide(ref) {
        case .action: break
        case .cyclicAncestry:
            add("relation.action.cyclic_ancestry", path, "Cannot resolve action \(ref): its class inheritance contains a cycle")
        case .wrongKind:
            add("relation.action.wrong_kind", path, "Expected an Action, but \(ref) does not derive from the foundation Action class")
        case .unresolved, nil:
            add("relation.action.unresolved", path, "Action reference \(ref) could not be resolved to a verified class")
        }
    }
}
