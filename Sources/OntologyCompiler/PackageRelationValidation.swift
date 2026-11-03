import OntologyRules

extension RelationEndpointNames {
    static func authored(in definition: JSONObject) -> Self? {
        RelationEndpointNamesSpec().decide(Set(definition.keys))
    }
}

extension OntologyCompiler {
    func validateRelations(
        _ relations: JSONObject,
        classes: JSONObject,
        bindings: PackageImportBindings,
        packageNamespace: String
    ) {
        let classNames = Set(classes.keys)
        let actionKind = RelationActionDecisionSpec(
            packageNamespace: packageNamespace,
            classBases: classes.compactMapValues { ($0 as? JSONObject)?["extends"] as? String },
            foundations: bindings.foundations
        )
        for name in relations.keys.sorted() {
            let path = "spec.relations.\(name)"
            validateSymbolName(name, path: path, code: "relation.name.invalid")
            guard let definition = relations[name] as? JSONObject else {
                add("relation.type", path, "Relation definition must be an object")
                continue
            }
            validateKnownKeys(definition, allowed: ["subject", "object", "domain", "range", "action", "cardinality", "description", "layer"], path: path)
            validateLayer(definition, path: path)

            guard let fields = RelationEndpointNames.authored(in: definition) else {
                add("relation.endpoints.mixed", path, "Use subject and object together, or domain and range together")
                continue
            }
            if let action = definition["action"] {
                validateRelationAction(action, path: "\(path).action", spec: actionKind)
            } else if fields == .acting {
                add("relation.action.required", "\(path).action", "An action is required between subject and object")
            }
            let subject = fields.subject
            if let ref = requiredString(definition, subject, path: "\(path).\(subject)", code: "relation.\(subject).required"),
               !resolves(ref, localNames: classNames, packageNamespace: packageNamespace, bindings: bindings) {
                add("relation.\(subject).unresolved", "\(path).\(subject)", "Relation \(subject) reference \(ref) cannot be resolved")
            }

            let object = fields.object
            guard let value = definition[object] else {
                add("relation.\(object).required", "\(path).\(object)", "Relation \(object) is required")
                continue
            }
            validateRelationRange(value, field: object, path: "\(path).\(object)", classes: classNames, namespace: packageNamespace, bindings: bindings)
        }
    }

    private func validateRelationRange(_ value: Any, field: String, path: String, classes: Set<String>, namespace: String, bindings: PackageImportBindings) {
        func validateRef(_ ref: String?, at site: String) {
            guard let ref else {
                add("relation.\(field).type", site, "Relation \(field) member must be a reference string")
                return
            }
            if !resolves(ref, localNames: classes, packageNamespace: namespace, bindings: bindings) {
                add("relation.\(field).unresolved", site, "Relation \(field) reference \(ref) cannot be resolved")
            }
        }

        switch RelationRangeShapeDecisionSpec().sourceShape(of: value) {
        case .scalarRef(let ref):
            validateRef(ref, at: path)
        case .oneOfMembers(let members) where !members.isEmpty:
            for (index, member) in members.enumerated() {
                validateRef(member, at: "\(path).oneOf[\(index)]")
            }
        case .oneOfMembers, .invalid:
            add("relation.\(field).type", path, "Relation \(field) must be a reference string or oneOf reference list")
        }
    }

    private func validateRelationAction(_ value: Any, path: String, spec: RelationActionDecisionSpec) {
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
