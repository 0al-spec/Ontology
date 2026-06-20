import Foundation
import OntologyRules

struct ClassValidationContext {
    let classNames: Set<String>
    let stateMachineNames: Set<String>
    let importNamespaces: Set<String>
    let packageNamespace: String
}

struct TriggerNames {
    var commands = Set<String>()
    var events = Set<String>()
}

extension OntologyCompiler {
    func validate(_ package: LoadedPackage) {
        let spec = package.spec
        validateKnownKeys(
            spec,
            allowed: ["imports", "classes", "protocols", "relations", "policies", "stateMachines", "compatibility"],
            path: "spec"
        )

        let imports = requiredArray(spec, "imports", path: "spec.imports", code: "spec.required")
        let importNamespaces = collectImportNamespaces(imports)
        let classes = requiredObject(spec, "classes", path: "spec.classes", code: "spec.required") ?? [:]
        let relations = requiredObject(spec, "relations", path: "spec.relations", code: "spec.required") ?? [:]
        let policies = requiredObject(spec, "policies", path: "spec.policies", code: "spec.required") ?? [:]
        let stateMachines = requiredObject(spec, "stateMachines", path: "spec.stateMachines", code: "spec.required") ?? [:]

        if imports.isEmpty { add("imports.empty", "spec.imports", "spec.imports must contain at least one import") }
        if classes.isEmpty { add("classes.empty", "spec.classes", "spec.classes must contain at least one class") }
        if relations.isEmpty { add("relations.empty", "spec.relations", "spec.relations must contain at least one relation") }
        if policies.isEmpty { add("policies.empty", "spec.policies", "spec.policies must contain at least one policy") }
        if stateMachines.isEmpty { add("stateMachines.empty", "spec.stateMachines", "spec.stateMachines must contain at least one state machine") }

        let classNames = Set(classes.keys)
        let policyNames = Set(policies.keys)
        let stateMachineNames = Set(stateMachines.keys)

        let protocols = (spec["protocols"] as? JSONObject) ?? [:]
        let protocolNames = Set(protocols.keys)

        validateProtocols(protocols)
        let classContext = ClassValidationContext(
            classNames: classNames,
            stateMachineNames: stateMachineNames,
            importNamespaces: importNamespaces,
            packageNamespace: package.namespace
        )
        let triggerNames = validateClasses(classes, context: classContext)
        validateImplementsRefs(
            classes,
            protocolNames: protocolNames,
            importNamespaces: importNamespaces,
            packageNamespace: package.namespace
        )
        validateRelations(
            relations,
            classNames: classNames,
            importNamespaces: importNamespaces,
            packageNamespace: package.namespace
        )
        validatePolicies(
            policies,
            policyNames: policyNames,
            classNames: classNames,
            importNamespaces: importNamespaces,
            packageNamespace: package.namespace
        )
        validateStateMachines(
            stateMachines,
            triggerNames: triggerNames,
            packageNamespace: package.namespace
        )
        validateProtocolConformance(
            classes: classes,
            protocols: protocols,
            relations: relations,
            packageNamespace: package.namespace
        )
    }

    func collectImportNamespaces(_ imports: [Any]) -> Set<String> {
        var namespaces = Set<String>()
        for (index, item) in imports.enumerated() {
            let path = "spec.imports[\(index)]"
            guard let importObject = item as? JSONObject else {
                add("imports.type", path, "Import entry must be an object")
                continue
            }
            validateKnownKeys(importObject, allowed: ["id", "namespace", "version"], path: path)
            _ = requiredString(importObject, "id", path: "\(path).id", code: "imports.required")
            _ = requiredString(importObject, "version", path: "\(path).version", code: "imports.required")
            if let namespace = string(importObject["namespace"]) {
                namespaces.insert(namespace)
            }
        }
        return namespaces
    }

    func validateClasses(
        _ classes: JSONObject,
        context: ClassValidationContext
    ) -> TriggerNames {
        var triggerNames = TriggerNames()
        for name in classes.keys.sorted() {
            let path = "spec.classes.\(name)"
            validateSymbolName(name, path: path, code: "class.name.invalid")
            guard let definition = classes[name] as? JSONObject else {
                add("class.type", path, "Class definition must be an object")
                continue
            }

            validateKnownKeys(definition, allowed: ["extends", "implements", "description", "central", "lifecycle", "aliases", "fields", "layer"], path: path)
            validateLayer(definition, path: path)
            let extendsValue = definition["extends"]
            if let extendsArray = extendsValue as? [Any], !extendsArray.isEmpty {
                add("class.extends.multiple", "\(path).extends", "Class extends must be one scalar reference; multiple inheritance is not allowed")
            } else if let extends = string(extendsValue) {
                if !resolves(
                    extends,
                    localNames: context.classNames,
                    packageNamespace: context.packageNamespace,
                    importNamespaces: context.importNamespaces
                ) {
                    add("class.extends.unresolved", "\(path).extends", "Class base reference \(extends) cannot be resolved")
                }
                if refName(extends) == "Command" {
                    triggerNames.commands.insert(name)
                }
                if refName(extends) == "Event" {
                    triggerNames.events.insert(name)
                }
            } else {
                add("class.extends.required", "\(path).extends", "Class extends is required and must be a scalar reference")
            }

            _ = requiredString(definition, "description", path: "\(path).description", code: "class.description.required")

            if let lifecycle = string(definition["lifecycle"]), !context.stateMachineNames.contains(lifecycle) {
                add("class.lifecycle.unresolved", "\(path).lifecycle", "Lifecycle state machine \(lifecycle) cannot be resolved")
            }
            validateClassFields(definition["fields"], path: "\(path).fields")
        }
        return triggerNames
    }

    func validateClassFields(_ value: Any?, path: String) {
        guard let value else { return }
        guard let fields = value as? JSONObject else {
            add("class.fields.type", path, "Class fields must be an object")
            return
        }
        for name in fields.keys.sorted() {
            let fieldPath = "\(path).\(name)"
            validateClassFieldName(name, path: fieldPath)
            guard let definition = fields[name] as? JSONObject else {
                add("class.field.type", fieldPath, "Class field definition must be an object")
                continue
            }
            validateKnownKeys(definition, allowed: ["type", "required", "description"], path: fieldPath)
            if let type = requiredString(definition, "type", path: "\(fieldPath).type", code: "class.field.type.required"),
               !OntologyFieldTypeSpec().isSatisfiedBy(OntologyFieldType(rawValue: type)) {
                add("class.field.type.unsupported", "\(fieldPath).type", "Class field type \(type) is not supported")
            }
            _ = requiredBool(definition, "required", path: "\(fieldPath).required", code: "class.field.required.required")
            if definition.keys.contains("description"), string(definition["description"]) == nil {
                add("class.field.description.type", "\(fieldPath).description", "Class field description must be a string")
            }
        }
    }

    func validateLayer(_ definition: JSONObject, path: String) {
        guard definition.keys.contains("layer") else { return }
        guard let layer = string(definition["layer"]) else {
            add("ontology.layer.type", "\(path).layer", "Ontology layer must be a string")
            return
        }
        if !OntologyLayerSpec().isSatisfiedBy(OntologyLayer(rawValue: layer)) {
            add("ontology.layer.invalid", "\(path).layer", "Ontology layer \(layer) is not supported")
        }
    }

    func validateImplementsRefs(
        _ classes: JSONObject,
        protocolNames: Set<String>,
        importNamespaces: Set<String>,
        packageNamespace: String
    ) {
        for name in classes.keys.sorted() {
            guard let definition = classes[name] as? JSONObject,
                  let implements = definition["implements"] else { continue }
            let path = "spec.classes.\(name)"
            guard let refs = implements as? [Any] else {
                add("class.implements.type", "\(path).implements", "implements must be an array")
                continue
            }
            for (index, refValue) in refs.enumerated() {
                guard let ref = string(refValue),
                      resolves(ref, localNames: protocolNames, packageNamespace: packageNamespace, importNamespaces: importNamespaces)
                else {
                    add("protocol.unresolved", "\(path).implements[\(index)]", "Implemented protocol reference cannot be resolved")
                    continue
                }
                if ref.contains(":"),
                   !ref.hasPrefix("\(packageNamespace):") {
                    warn(
                        "protocol.imported.emit_unsupported",
                        "\(path).implements[\(index)]",
                        "Imported protocol reference \(ref) resolves but is not emitted as a local TypeScript protocol interface"
                    )
                }
            }
        }
    }

    func validateRelations(
        _ relations: JSONObject,
        classNames: Set<String>,
        importNamespaces: Set<String>,
        packageNamespace: String
    ) {
        for name in relations.keys.sorted() {
            let path = "spec.relations.\(name)"
            validateSymbolName(name, path: path, code: "relation.name.invalid")
            guard let definition = relations[name] as? JSONObject else {
                add("relation.type", path, "Relation definition must be an object")
                continue
            }
            validateKnownKeys(definition, allowed: ["domain", "range", "cardinality", "description", "layer"], path: path)
            validateLayer(definition, path: path)

            if let domain = requiredString(definition, "domain", path: "\(path).domain", code: "relation.domain.required"),
               !resolves(domain, localNames: classNames, packageNamespace: packageNamespace, importNamespaces: importNamespaces) {
                add("relation.domain.unresolved", "\(path).domain", "Relation domain reference \(domain) cannot be resolved")
            }

            guard let rangeValue = definition["range"] else {
                add("relation.range.required", "\(path).range", "Relation range is required")
                continue
            }
            let refs = relationRangeRefs(rangeValue)
            if refs.isEmpty {
                add("relation.range.type", "\(path).range", "Relation range must be a reference string or oneOf reference list")
            }
            for (index, ref) in refs.enumerated()
            where !resolves(ref, localNames: classNames, packageNamespace: packageNamespace, importNamespaces: importNamespaces) {
                add("relation.range.unresolved", "\(path).range[\(index)]", "Relation range reference \(ref) cannot be resolved")
            }
        }
    }

    func validatePolicies(
        _ policies: JSONObject,
        policyNames: Set<String>,
        classNames: Set<String>,
        importNamespaces: Set<String>,
        packageNamespace: String
    ) {
        for name in policies.keys.sorted() {
            let path = "spec.policies.\(name)"
            validateSymbolName(name, path: path, code: "policy.name.invalid")
            guard let definition = policies[name] as? JSONObject else {
                add("policy.type", path, "Policy definition must be an object")
                continue
            }
            validateKnownKeys(definition, allowed: ["extends", "enforceability", "appliesTo", "text", "layer"], path: path)
            validateLayer(definition, path: path)

            if let extends = requiredString(definition, "extends", path: "\(path).extends", code: "policy.extends.required"),
               !resolves(extends, localNames: policyNames, packageNamespace: packageNamespace, importNamespaces: importNamespaces) {
                add("policy.extends.unresolved", "\(path).extends", "Policy base reference \(extends) cannot be resolved")
            }

            if let enforceability = requiredString(definition, "enforceability", path: "\(path).enforceability", code: "policy.enforceability.required"),
               !AllowedPolicyEnforceabilitySpec().isSatisfiedBy(PolicyEnforceability(rawValue: enforceability)) {
                add("policy.enforceability.invalid", "\(path).enforceability", "Policy enforceability \(enforceability) is invalid")
            }

            let appliesTo = requiredArray(definition, "appliesTo", path: "\(path).appliesTo", code: "policy.appliesTo.required")
            if appliesTo.isEmpty {
                add("policy.appliesTo.empty", "\(path).appliesTo", "Policy appliesTo must contain at least one target")
            }
            for (index, refValue) in appliesTo.enumerated() {
                guard let ref = string(refValue),
                      resolves(ref, localNames: classNames, packageNamespace: packageNamespace, importNamespaces: importNamespaces)
                else {
                    add("policy.appliesTo.unresolved", "\(path).appliesTo[\(index)]", "Policy target cannot be resolved")
                    continue
                }
            }

            _ = requiredString(definition, "text", path: "\(path).text", code: "policy.text.required")
        }
    }

    func validateStateMachines(
        _ stateMachines: JSONObject,
        triggerNames: TriggerNames,
        packageNamespace: String
    ) {
        for name in stateMachines.keys.sorted() {
            let path = "spec.stateMachines.\(name)"
            validateSymbolName(name, path: path, code: "stateMachine.name.invalid")
            guard let definition = stateMachines[name] as? JSONObject else {
                add("stateMachine.type", path, "State machine definition must be an object")
                continue
            }
            validateKnownKeys(definition, allowed: ["states", "transitions", "layer"], path: path)
            validateLayer(definition, path: path)

            let stateSet = validateStateNames(definition, path: path)
            validateTransitions(definition, path: path, stateSet: stateSet, triggerNames: triggerNames, packageNamespace: packageNamespace)
        }
    }

    func validateStateNames(_ definition: JSONObject, path: String) -> Set<String> {
        let states = requiredArray(definition, "states", path: "\(path).states", code: "state.states.required").compactMap { string($0) }
        let stateSet = Set(states)
        if stateSet.isEmpty {
            add("state.states.empty", "\(path).states", "State machine must contain at least one state")
        }
        for (index, state) in states.enumerated() {
            validateStateName(state, path: "\(path).states[\(index)]", code: "state.name.invalid")
        }
        return stateSet
    }

    func validateTransitions(
        _ definition: JSONObject,
        path: String,
        stateSet: Set<String>,
        triggerNames: TriggerNames,
        packageNamespace: String
    ) {
        let transitions = requiredArray(definition, "transitions", path: "\(path).transitions", code: "state.transitions.required")
        if transitions.isEmpty {
            add("state.transitions.empty", "\(path).transitions", "State machine must contain at least one transition")
        }
        for (index, transitionValue) in transitions.enumerated() {
            let transitionPath = "\(path).transitions[\(index)]"
            guard let transition = transitionValue as? JSONObject else {
                add("state.transition.type", transitionPath, "Transition must be an object")
                continue
            }
            validateKnownKeys(transition, allowed: ["from", "to", "command", "event"], path: transitionPath)
            validateTransitionEndpoints(transition, path: transitionPath, stateSet: stateSet)
            validateTransitionTriggers(transition, path: transitionPath, triggerNames: triggerNames, packageNamespace: packageNamespace)
        }
    }

    func validateTransitionEndpoints(_ transition: JSONObject, path: String, stateSet: Set<String>) {
        if let from = requiredString(transition, "from", path: "\(path).from", code: "state.transition.from.required"),
           !DeclaredStateSpec().isSatisfiedBy(StateMembershipContext(state: from, states: stateSet)) {
            add("state.transition.invalid_state", "\(path).from", "Transition source state \(from) does not exist")
        }
        if let to = requiredString(transition, "to", path: "\(path).to", code: "state.transition.to.required"),
           !DeclaredStateSpec().isSatisfiedBy(StateMembershipContext(state: to, states: stateSet)) {
            add("state.transition.invalid_state", "\(path).to", "Transition target state \(to) does not exist")
        }
    }

    func validateTransitionTriggers(
        _ transition: JSONObject,
        path: String,
        triggerNames: TriggerNames,
        packageNamespace: String
    ) {
        if let command = string(transition["command"]),
           !isLocalTrigger(command, names: triggerNames.commands, packageNamespace: packageNamespace) {
            add("state.transition.trigger_unresolved", "\(path).command", "Command trigger \(command) cannot be resolved")
        }
        if let event = string(transition["event"]),
           !isLocalTrigger(event, names: triggerNames.events, packageNamespace: packageNamespace) {
            add("state.transition.trigger_unresolved", "\(path).event", "Event trigger \(event) cannot be resolved")
        }
    }
}
