import Foundation
import OntologyRules

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
        var commandNames = Set<String>()
        var eventNames = Set<String>()

        let protocols = (spec["protocols"] as? JSONObject) ?? [:]
        let protocolNames = Set(protocols.keys)

        validateProtocols(
            protocols,
            packageNamespace: package.namespace
        )
        validateClasses(
            classes,
            classNames: classNames,
            stateMachineNames: stateMachineNames,
            importNamespaces: importNamespaces,
            packageNamespace: package.namespace,
            commandNames: &commandNames,
            eventNames: &eventNames
        )
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
            commandNames: commandNames,
            eventNames: eventNames,
            packageNamespace: package.namespace
        )
        validateProtocolConformance(
            classes: classes,
            protocols: protocols,
            relations: relations,
            packageNamespace: package.namespace
        )
    }

    func validateProtocols(
        _ protocols: JSONObject,
        packageNamespace: String
    ) {
        for name in protocols.keys.sorted() {
            let path = "spec.protocols.\(name)"
            validate(name, path: path, code: "protocol.name.invalid") {
                OntologySymbolNameSpec().isSatisfiedBy($0)
            }
            guard let definition = protocols[name] as? JSONObject else {
                add("protocol.type", path, "Protocol definition must be an object")
                continue
            }
            validateKnownKeys(
                definition,
                allowed: ["description", "requiredFields", "requiredRelations", "semanticConstraints"],
                path: path
            )
            _ = requiredString(definition, "description", path: "\(path).description", code: "protocol.description.required")
            for (index, fieldValue) in (definition["requiredFields"] as? [Any] ?? []).enumerated() {
                guard let field = string(fieldValue) else { continue }
                validate(field, path: "\(path).requiredFields[\(index)]", code: "protocol.field.name.invalid") {
                    OntologySymbolNameSpec().isSatisfiedBy($0)
                }
            }
            for (index, relValue) in (definition["requiredRelations"] as? [Any] ?? []).enumerated() {
                guard let rel = string(relValue) else { continue }
                validate(rel, path: "\(path).requiredRelations[\(index)]", code: "protocol.relation.name.invalid") {
                    OntologySymbolNameSpec().isSatisfiedBy($0)
                }
            }
        }
    }

    func validateProtocolConformance(
        classes: JSONObject,
        protocols: JSONObject,
        relations: JSONObject,
        packageNamespace: String
    ) {
        var classRelationDomains: [String: Set<String>] = [:]
        for (relationName, value) in relations {
            guard let definition = value as? JSONObject,
                  let domain = string(definition["domain"]) else { continue }
            let domainName = refName(domain)
            classRelationDomains[domainName, default: []].insert(relationName)
        }

        for (className, value) in classes {
            guard let definition = value as? JSONObject,
                  let implementsList = definition["implements"] as? [Any] else { continue }
            for refValue in implementsList {
                guard let ref = string(refValue) else { continue }
                let protoName: String
                let parts = ref.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let ns = String(parts[0])
                    if ns != packageNamespace { continue }
                    protoName = String(parts[1])
                } else {
                    protoName = ref
                }
                guard let protoDef = protocols[protoName] as? JSONObject,
                      let requiredRels = protoDef["requiredRelations"] as? [Any] else { continue }
                let requiredRelNames = requiredRels.compactMap { string($0) }
                let domains = classRelationDomains[className] ?? []
                let context = ProtocolConformanceContext(
                    protocolRequiredRelations: requiredRelNames,
                    classRelationDomains: domains
                )
                if !ProtocolRelationConformanceSpec().isSatisfiedBy(context) {
                    for req in requiredRelNames where !domains.contains(req) {
                        add(
                            "protocol.relation.missing",
                            "spec.classes.\(className).implements",
                            "Class \(className) implements \(protoName) but is missing required relation \(req)"
                        )
                    }
                }
            }
        }
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
        classNames: Set<String>,
        stateMachineNames: Set<String>,
        importNamespaces: Set<String>,
        packageNamespace: String,
        commandNames: inout Set<String>,
        eventNames: inout Set<String>
    ) {
        for name in classes.keys.sorted() {
            let path = "spec.classes.\(name)"
            validate(name, path: path, code: "class.name.invalid") {
                OntologySymbolNameSpec().isSatisfiedBy($0)
            }
            guard let definition = classes[name] as? JSONObject else {
                add("class.type", path, "Class definition must be an object")
                continue
            }

            validateKnownKeys(definition, allowed: ["extends", "implements", "description", "central", "lifecycle", "aliases"], path: path)
            let extendsValue = definition["extends"]
            if let extendsArray = extendsValue as? [Any], !extendsArray.isEmpty {
                add("class.extends.multiple", "\(path).extends", "Class extends must be one scalar reference; multiple inheritance is not allowed")
            } else if let extends = string(extendsValue) {
                if !resolves(extends, localNames: classNames, packageNamespace: packageNamespace, importNamespaces: importNamespaces) {
                    add("class.extends.unresolved", "\(path).extends", "Class base reference \(extends) cannot be resolved")
                }
                if refName(extends) == "Command" {
                    commandNames.insert(name)
                }
                if refName(extends) == "Event" {
                    eventNames.insert(name)
                }
            } else {
                add("class.extends.required", "\(path).extends", "Class extends is required and must be a scalar reference")
            }

            _ = requiredString(definition, "description", path: "\(path).description", code: "class.description.required")

            if let lifecycle = string(definition["lifecycle"]), !stateMachineNames.contains(lifecycle) {
                add("class.lifecycle.unresolved", "\(path).lifecycle", "Lifecycle state machine \(lifecycle) cannot be resolved")
            }
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
            validate(name, path: path, code: "relation.name.invalid") {
                OntologySymbolNameSpec().isSatisfiedBy($0)
            }
            guard let definition = relations[name] as? JSONObject else {
                add("relation.type", path, "Relation definition must be an object")
                continue
            }
            validateKnownKeys(definition, allowed: ["domain", "range", "cardinality", "description"], path: path)

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
            validate(name, path: path, code: "policy.name.invalid") {
                OntologySymbolNameSpec().isSatisfiedBy($0)
            }
            guard let definition = policies[name] as? JSONObject else {
                add("policy.type", path, "Policy definition must be an object")
                continue
            }
            validateKnownKeys(definition, allowed: ["extends", "enforceability", "appliesTo", "text"], path: path)

            if let extends = requiredString(definition, "extends", path: "\(path).extends", code: "policy.extends.required"),
               !resolves(extends, localNames: policyNames, packageNamespace: packageNamespace, importNamespaces: importNamespaces) {
                add("policy.extends.unresolved", "\(path).extends", "Policy base reference \(extends) cannot be resolved")
            }

            if let enforceability = requiredString(definition, "enforceability", path: "\(path).enforceability", code: "policy.enforceability.required"),
               !AllowedPolicyEnforceabilitySpec().isSatisfiedBy(enforceability) {
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
        commandNames: Set<String>,
        eventNames: Set<String>,
        packageNamespace: String
    ) {
        for name in stateMachines.keys.sorted() {
            let path = "spec.stateMachines.\(name)"
            validate(name, path: path, code: "stateMachine.name.invalid") {
                OntologySymbolNameSpec().isSatisfiedBy($0)
            }
            guard let definition = stateMachines[name] as? JSONObject else {
                add("stateMachine.type", path, "State machine definition must be an object")
                continue
            }
            validateKnownKeys(definition, allowed: ["states", "transitions"], path: path)

            let states = requiredArray(definition, "states", path: "\(path).states", code: "state.states.required").compactMap { string($0) }
            let stateSet = Set(states)
            if stateSet.isEmpty {
                add("state.states.empty", "\(path).states", "State machine must contain at least one state")
            }
            for (index, state) in states.enumerated() {
                validate(state, path: "\(path).states[\(index)]", code: "state.name.invalid") {
                    OntologyStateNameSpec().isSatisfiedBy($0)
                }
            }

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
                if let from = requiredString(transition, "from", path: "\(transitionPath).from", code: "state.transition.from.required"),
                   !DeclaredStateSpec().isSatisfiedBy(StateMembershipContext(state: from, states: stateSet)) {
                    add("state.transition.invalid_state", "\(transitionPath).from", "Transition source state \(from) does not exist")
                }
                if let to = requiredString(transition, "to", path: "\(transitionPath).to", code: "state.transition.to.required"),
                   !DeclaredStateSpec().isSatisfiedBy(StateMembershipContext(state: to, states: stateSet)) {
                    add("state.transition.invalid_state", "\(transitionPath).to", "Transition target state \(to) does not exist")
                }
                if let command = string(transition["command"]),
                   !isLocalTrigger(command, names: commandNames, packageNamespace: packageNamespace) {
                    add("state.transition.trigger_unresolved", "\(transitionPath).command", "Command trigger \(command) cannot be resolved")
                }
                if let event = string(transition["event"]),
                   !isLocalTrigger(event, names: eventNames, packageNamespace: packageNamespace) {
                    add("state.transition.trigger_unresolved", "\(transitionPath).event", "Event trigger \(event) cannot be resolved")
                }
            }
        }
    }
}
