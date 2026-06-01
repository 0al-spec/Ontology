import CryptoKit
import Foundation
import Yams

typealias JSONObject = [String: Any]

struct Diagnostic: Encodable {
    let code: String
    let severity: String
    let path: String
    let message: String
    let hint: String?
}

struct LoadedPackage {
    let path: String
    let source: String
    let root: JSONObject
    let metadata: JSONObject
    let spec: JSONObject
    let id: String
    let namespace: String
    let version: String
}

final class OntologyCompiler {
    private let apiVersion = "ontology.specgraph.io/v1alpha1"
    private let kind = "DomainOntologyPackage"
    private let namePattern = #"^[A-Za-z][A-Za-z0-9_]*$"#
    private let statePattern = #"^[a-z][a-z0-9_]*$"#
    private let conceptPattern = #"^([A-Za-z][A-Za-z0-9_]*|[A-Za-z][A-Za-z0-9_.-]*:[A-Za-z][A-Za-z0-9_]*)$"#
    private let idPattern = #"^[a-z][a-z0-9]*(\.[a-z0-9][a-z0-9-]*)+$"#
    private let namespacePattern = #"^[a-z][a-z0-9-]*$"#
    private let versionPattern = #"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([-+][0-9A-Za-z.-]+)?$"#
    private let unsafeKeys = Set([
        "eval", "exec", "executable", "expression", "hook", "hooks",
        "plugin", "plugins", "posthook", "prehook", "script", "scripts"
    ])
    private let unsafeValuePatterns = [
        #"\$\("#, #"`"#, #"<%"#, #"eval\("#, #"child_process"#,
        #"subprocess"#, #"os\.system"#, #"Runtime\.getRuntime"#
    ]
    private let unsafeTagPattern = #"!![A-Za-z0-9_.:-]+|!<[^>]+>"#

    private var diagnostics: [Diagnostic] = []

    func check(path: String) -> [Diagnostic] {
        diagnostics = []
        if let package = load(path: path) {
            validate(package)
        }
        return diagnostics.sorted {
            [$0.path, $0.code, $0.message].joined(separator: "\u{1f}") <
                [$1.path, $1.code, $1.message].joined(separator: "\u{1f}")
        }
    }

    func compile(path: String, outDirectory: String) throws -> [Diagnostic] {
        diagnostics = []
        guard let package = load(path: path) else {
            return diagnostics
        }
        validate(package)
        if hasErrors(diagnostics) {
            return diagnostics
        }

        let ir = normalize(package)
        try emit(ir: ir, to: outDirectory)
        return diagnostics
    }

    func validateSpecGraph(bindingPath: String, ontologyIRPath: String, outDirectory: String) throws -> (resolved: Int, gaps: Int) {
        let ir = try loadJSON(path: ontologyIRPath)
        let namespace = string(ir["namespace"]) ?? ""
        let index = conceptRefIndex(ir)
        let documents = try loadYAMLDocuments(path: bindingPath)
        let imports = collectOntologyImports(documents)
        let occurrences = collectRefOccurrences(documents, namespace: namespace)

        var resolvedRefs = [JSONObject]()
        var gaps = [JSONObject]()
        var seenResolved = Set<String>()
        var seenGaps = Set<String>()

        for occurrence in occurrences.sorted(by: { $0.ref < $1.ref }) {
            if let conceptRef = index[occurrence.ref] {
                if !seenResolved.contains(occurrence.ref) {
                    resolvedRefs.append(conceptRef)
                    seenResolved.insert(occurrence.ref)
                }
            } else if !seenGaps.contains(occurrence.ref) {
                gaps.append(ontologyGap(for: occurrence, ir: ir, ordinal: gaps.count + 1))
                seenGaps.insert(occurrence.ref)
            }
        }

        let outURL = URL(fileURLWithPath: outDirectory)
        try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
        try writeYAML([
            "apiVersion": "specgraph.io/v1alpha1",
            "kind": "ConceptRefSet",
            "metadata": [
                "ontology": string(ir["id"]) ?? "",
                "namespace": namespace,
                "version": string(ir["version"]) ?? ""
            ],
            "spec": [
                "refs": resolvedRefs
            ]
        ], to: outURL.appendingPathComponent("concept-refs.yaml"))

        try writeYAML(lockfile(imports: imports, ir: ir, index: index), to: outURL.appendingPathComponent("ontology.lock.yaml"))

        try writeYAML([
            "apiVersion": "specgraph.io/v1alpha1",
            "kind": "OntologyGapSet",
            "metadata": [
                "source": bindingPath
            ],
            "spec": [
                "gaps": gaps
            ]
        ], to: outURL.appendingPathComponent("ontology-gaps.yaml"))

        return (resolvedRefs.count, gaps.count)
    }

    func diffPackages(from fromPath: String, to toPath: String, outPath: String) throws -> [Diagnostic] {
        diagnostics = []
        guard let fromPackage = load(path: fromPath), let toPackage = load(path: toPath) else {
            return diagnostics
        }
        validate(fromPackage)
        validate(toPackage)
        if hasErrors(diagnostics) {
            return diagnostics
        }

        let fromIR = normalize(fromPackage)
        let toIR = normalize(toPackage)
        let report = compatibilityReport(fromIR: fromIR, toIR: toIR)
        try writeYAML(report, to: URL(fileURLWithPath: outPath))
        return diagnostics
    }

    func hasErrors(_ diagnostics: [Diagnostic]) -> Bool {
        diagnostics.contains { $0.severity == "error" }
    }

    func printDiagnostics(_ diagnostics: [Diagnostic]) {
        for diagnostic in diagnostics {
            var line = "\(diagnostic.severity) \(diagnostic.code) \(diagnostic.path): \(diagnostic.message)"
            if let hint = diagnostic.hint {
                line += " Hint: \(hint)"
            }
            print(line)
        }
    }

    private func load(path: String) -> LoadedPackage? {
        let url = URL(fileURLWithPath: path)
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            add("io.read", path, "Cannot read file: \(error.localizedDescription)")
            return nil
        }

        scanUnsafeSource(source, filePath: path)

        let parsed: Any?
        do {
            parsed = try Yams.load(yaml: source)
        } catch {
            add("yaml.parse", path, "YAML parse error: \(error)")
            return nil
        }

        guard let root = parsed as? JSONObject else {
            add("package.type", "package", "Package root must be a mapping object")
            return nil
        }

        scanUnsafeNode(root, path: "package")
        validateKnownKeys(root, allowed: ["apiVersion", "kind", "metadata", "spec"], path: "package")

        if string(root["apiVersion"]) != apiVersion {
            add("apiVersion.invalid", "apiVersion", "apiVersion must be \(apiVersion)")
        }
        if string(root["kind"]) != kind {
            add("kind.invalid", "kind", "kind must be \(kind)")
        }

        guard let metadata = root["metadata"] as? JSONObject else {
            add("metadata.required", "metadata", "metadata object is required")
            return nil
        }
        guard let spec = root["spec"] as? JSONObject else {
            add("spec.required", "spec", "spec object is required")
            return nil
        }

        validateKnownKeys(metadata, allowed: ["id", "namespace", "version", "publisher", "source", "approvalStatus"], path: "metadata")

        let id = requiredString(metadata, "id", path: "metadata.id", code: "metadata.required") ?? ""
        let namespace = requiredString(metadata, "namespace", path: "metadata.namespace", code: "metadata.required") ?? ""
        let version = requiredString(metadata, "version", path: "metadata.version", code: "metadata.required") ?? ""

        validatePattern(id, idPattern, path: "metadata.id", code: "metadata.invalid")
        validatePattern(namespace, namespacePattern, path: "metadata.namespace", code: "metadata.invalid")
        validatePattern(version, versionPattern, path: "metadata.version", code: "metadata.invalid")

        return LoadedPackage(
            path: path,
            source: source,
            root: root,
            metadata: metadata,
            spec: spec,
            id: id,
            namespace: namespace,
            version: version
        )
    }

    private func validate(_ package: LoadedPackage) {
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

        validateClasses(
            classes,
            classNames: classNames,
            stateMachineNames: stateMachineNames,
            importNamespaces: importNamespaces,
            packageNamespace: package.namespace,
            commandNames: &commandNames,
            eventNames: &eventNames
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
    }

    private func collectImportNamespaces(_ imports: [Any]) -> Set<String> {
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

    private func validateClasses(
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
            validatePattern(name, namePattern, path: path, code: "class.name.invalid")
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

            if let implements = definition["implements"] {
                guard let refs = implements as? [Any] else {
                    add("class.implements.type", "\(path).implements", "implements must be an array")
                    continue
                }
                for (index, refValue) in refs.enumerated() {
                    guard let ref = string(refValue),
                          matches(ref, conceptPattern),
                          (isImported(ref, importNamespaces) || isLocal(ref, localNames: classNames, packageNamespace: packageNamespace))
                    else {
                        add("protocol.unresolved", "\(path).implements[\(index)]", "Implemented protocol/class reference cannot be resolved")
                        continue
                    }
                }
            }

            if let lifecycle = string(definition["lifecycle"]), !stateMachineNames.contains(lifecycle) {
                add("class.lifecycle.unresolved", "\(path).lifecycle", "Lifecycle state machine \(lifecycle) cannot be resolved")
            }
        }
    }

    private func validateRelations(
        _ relations: JSONObject,
        classNames: Set<String>,
        importNamespaces: Set<String>,
        packageNamespace: String
    ) {
        for name in relations.keys.sorted() {
            let path = "spec.relations.\(name)"
            validatePattern(name, namePattern, path: path, code: "relation.name.invalid")
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

    private func validatePolicies(
        _ policies: JSONObject,
        policyNames: Set<String>,
        classNames: Set<String>,
        importNamespaces: Set<String>,
        packageNamespace: String
    ) {
        let allowedEnforceability = Set(["design", "runtime", "manual", "audit"])
        for name in policies.keys.sorted() {
            let path = "spec.policies.\(name)"
            validatePattern(name, namePattern, path: path, code: "policy.name.invalid")
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
               !allowedEnforceability.contains(enforceability) {
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

    private func validateStateMachines(
        _ stateMachines: JSONObject,
        commandNames: Set<String>,
        eventNames: Set<String>,
        packageNamespace: String
    ) {
        for name in stateMachines.keys.sorted() {
            let path = "spec.stateMachines.\(name)"
            validatePattern(name, namePattern, path: path, code: "stateMachine.name.invalid")
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
                validatePattern(state, statePattern, path: "\(path).states[\(index)]", code: "state.name.invalid")
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
                   !stateSet.contains(from) {
                    add("state.transition.invalid_state", "\(transitionPath).from", "Transition source state \(from) does not exist")
                }
                if let to = requiredString(transition, "to", path: "\(transitionPath).to", code: "state.transition.to.required"),
                   !stateSet.contains(to) {
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

    private func normalize(_ package: LoadedPackage) -> JSONObject {
        let spec = package.spec
        let imports = (spec["imports"] as? [Any] ?? []).compactMap { $0 as? JSONObject }
            .sorted { string($0["id"]) ?? "" < string($1["id"]) ?? "" }
            .map { importObject -> JSONObject in
                var normalized: JSONObject = [
                    "id": string(importObject["id"]) ?? "",
                    "version": string(importObject["version"]) ?? ""
                ]
                if let namespace = string(importObject["namespace"]) {
                    normalized["namespace"] = namespace
                }
                return normalized
            }

        let classesObject = spec["classes"] as? JSONObject ?? [:]
        let relationsObject = spec["relations"] as? JSONObject ?? [:]
        let policiesObject = spec["policies"] as? JSONObject ?? [:]
        let stateMachinesObject = spec["stateMachines"] as? JSONObject ?? [:]

        let classes = classesObject.keys.sorted().map { name -> JSONObject in
            let definition = classesObject[name] as? JSONObject ?? [:]
            let extends = string(definition["extends"]) ?? ""
            var normalized: JSONObject = [
                "id": name,
                "fqid": "\(package.namespace):\(name)",
                "uri": "ontology://\(package.id)/\(package.version)/classes/\(name)",
                "kind": refName(extends),
                "extends": normalizeRef(extends, namespace: package.namespace),
                "implements": (definition["implements"] as? [Any] ?? []).compactMap { string($0) }.map { normalizeRef($0, namespace: package.namespace) }.sorted(),
                "description": string(definition["description"]) ?? "",
                "central": (definition["central"] as? Bool) ?? false,
                "aliases": (definition["aliases"] as? [Any] ?? []).compactMap { string($0) }.sorted()
            ]
            if let lifecycle = string(definition["lifecycle"]) {
                normalized["lifecycle"] = lifecycle
            }
            return normalized
        }

        let relations = relationsObject.keys.sorted().map { name -> JSONObject in
            let definition = relationsObject[name] as? JSONObject ?? [:]
            var normalized: JSONObject = [
                "id": name,
                "fqid": "\(package.namespace):\(name)",
                "uri": "ontology://\(package.id)/\(package.version)/relations/\(name)",
                "domain": normalizeRef(string(definition["domain"]) ?? "", namespace: package.namespace),
                "range": normalizeRange(definition["range"], namespace: package.namespace)
            ]
            if let cardinality = definition["cardinality"] as? JSONObject {
                normalized["cardinality"] = cardinality
            }
            if let description = string(definition["description"]) {
                normalized["description"] = description
            }
            return normalized
        }

        let policies = policiesObject.keys.sorted().map { name -> JSONObject in
            let definition = policiesObject[name] as? JSONObject ?? [:]
            return [
                "id": name,
                "fqid": "\(package.namespace):\(name)",
                "extends": normalizeRef(string(definition["extends"]) ?? "", namespace: package.namespace),
                "enforceability": string(definition["enforceability"]) ?? "",
                "appliesTo": (definition["appliesTo"] as? [Any] ?? []).compactMap { string($0) }.map { normalizeRef($0, namespace: package.namespace) }.sorted(),
                "text": string(definition["text"]) ?? ""
            ]
        }

        let stateMachines = stateMachinesObject.keys.sorted().map { name -> JSONObject in
            let definition = stateMachinesObject[name] as? JSONObject ?? [:]
            let transitions = (definition["transitions"] as? [Any] ?? []).compactMap { $0 as? JSONObject }
                .map { transition -> JSONObject in
                    var normalized: JSONObject = [
                        "from": string(transition["from"]) ?? "",
                        "to": string(transition["to"]) ?? ""
                    ]
                    if let command = string(transition["command"]) {
                        normalized["command"] = normalizeRef(command, namespace: package.namespace)
                    }
                    if let event = string(transition["event"]) {
                        normalized["event"] = normalizeRef(event, namespace: package.namespace)
                    }
                    return normalized
                }
                .sorted { transitionSortKey($0) < transitionSortKey($1) }
            return [
                "id": name,
                "fqid": "\(package.namespace):\(name)",
                "states": (definition["states"] as? [Any] ?? []).compactMap { string($0) }.sorted(),
                "transitions": transitions
            ]
        }

        var ir: JSONObject = [
            "id": package.id,
            "namespace": package.namespace,
            "version": package.version,
            "sourceDigest": sha256(package.source),
            "imports": imports,
            "classes": classes,
            "relations": relations,
            "protocols": [],
            "policies": policies,
            "stateMachines": stateMachines,
            "diagnostics": []
        ]
        if let compatibility = spec["compatibility"] as? JSONObject {
            ir["compatibility"] = compatibility
        }
        return ir
    }

    private func emit(ir: JSONObject, to outDirectory: String) throws {
        let outURL = URL(fileURLWithPath: outDirectory)
        try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
        try write(json: ir, to: outURL.appendingPathComponent("ontology.normalized.json"))
        try write(text: emitRefs(ir), to: outURL.appendingPathComponent("refs.ts"))
        try write(text: emitTypes(ir), to: outURL.appendingPathComponent("types.ts"))
        try write(text: emitRelations(ir), to: outURL.appendingPathComponent("relations.ts"))
        try write(text: emitPolicies(ir), to: outURL.appendingPathComponent("policies.ts"))
        try write(text: emitStateMachines(ir), to: outURL.appendingPathComponent("state-machines.ts"))
        try write(text: emitRegistry(ir), to: outURL.appendingPathComponent("registry.ts"))
        try write(text: emitValidators(ir), to: outURL.appendingPathComponent("validators.ts"))
    }

    private func emitRefs(_ ir: JSONObject) -> String {
        let classes = ir["classes"] as? [JSONObject] ?? []
        let relations = ir["relations"] as? [JSONObject] ?? []
        let policies = ir["policies"] as? [JSONObject] ?? []
        let stateMachines = ir["stateMachines"] as? [JSONObject] ?? []

        let classRefs = classes.mapValuesById { refLiteral(ir: ir, item: $0, kindKey: "kind") }
        let relationRefs = relations.mapValuesById { refLiteral(ir: ir, item: $0, fixedKind: "Relation") }
        let policyRefs = policies.mapValuesById { refLiteral(ir: ir, item: $0, fixedKind: "Policy") }
        let stateMachineRefs = stateMachines.mapValuesById { refLiteral(ir: ir, item: $0, fixedKind: "StateMachine") }
        var allRefs = JSONObject()
        for source in [classRefs, relationRefs, policyRefs, stateMachineRefs] {
            for key in source.keys.sorted() {
                guard let ref = source[key] as? JSONObject,
                      let alias = ref["alias"] as? String
                else { continue }
                allRefs[alias] = ref
            }
        }

        return """
        // Generated by ontologyc. Do not edit manually.

        export type ConceptRef = {
          readonly ontology: string;
          readonly version: string;
          readonly namespace: string;
          readonly concept: string;
          readonly kindOfConcept: string;
          readonly alias: string;
          readonly uri: string;
        };

        export const classes = \(tsObject(classRefs)) as const;
        export const relations = \(tsObject(relationRefs)) as const;
        export const policies = \(tsObject(policyRefs)) as const;
        export const stateMachines = \(tsObject(stateMachineRefs)) as const;
        export const allRefs = \(tsObject(allRefs)) as const;

        """
    }

    private func emitTypes(_ ir: JSONObject) -> String {
        let classes = ir["classes"] as? [JSONObject] ?? []
        let interfaces = classes.map { item -> String in
            let id = string(item["id"]) ?? "Unknown"
            let fqid = string(item["fqid"]) ?? id
            return """
            export interface \(id) {
              readonly $type: "\(fqid)";
              readonly id?: string;
            }
            """
        }.joined(separator: "\n\n")
        return """
        // Generated by ontologyc. Do not edit manually.

        export type OntologyEntityId = string;

        \(interfaces)

        """
    }

    private func emitRelations(_ ir: JSONObject) -> String {
        let relations = ir["relations"] as? [JSONObject] ?? []
        return """
        // Generated by ontologyc. Do not edit manually.

        export const relationDefinitions = \(tsArray(relations)) as const;

        """
    }

    private func emitPolicies(_ ir: JSONObject) -> String {
        let policies = ir["policies"] as? [JSONObject] ?? []
        return """
        // Generated by ontologyc. Do not edit manually.

        export const policyDefinitions = \(tsArray(policies)) as const;

        """
    }

    private func emitStateMachines(_ ir: JSONObject) -> String {
        let stateMachines = ir["stateMachines"] as? [JSONObject] ?? []
        return """
        // Generated by ontologyc. Do not edit manually.

        export const stateMachineDefinitions = \(tsArray(stateMachines)) as const;

        """
    }

    private func emitRegistry(_ ir: JSONObject) -> String {
        let metadata: JSONObject = [
            "id": ir["id"] ?? "",
            "namespace": ir["namespace"] ?? "",
            "version": ir["version"] ?? "",
            "sourceDigest": ir["sourceDigest"] ?? ""
        ]
        return """
        // Generated by ontologyc. Do not edit manually.

        import { classes, relations, policies, stateMachines } from "./refs";
        import { relationDefinitions } from "./relations";
        import { policyDefinitions } from "./policies";
        import { stateMachineDefinitions } from "./state-machines";

        export const ontologyMetadata = \(tsObject(metadata)) as const;

        export const ontologyRegistry = {
          metadata: ontologyMetadata,
          refs: { classes, relations, policies, stateMachines },
          relations: relationDefinitions,
          policies: policyDefinitions,
          stateMachines: stateMachineDefinitions,
        } as const;

        """
    }

    private func emitValidators(_ ir: JSONObject) -> String {
        _ = ir
        return """
        // Generated by ontologyc. Do not edit manually.

        import { allRefs } from "./refs";

        export type KnownOntologyRef = keyof typeof allRefs;

        export function isKnownOntologyRef(value: string): value is KnownOntologyRef {
          return Object.prototype.hasOwnProperty.call(allRefs, value);
        }

        export function assertKnownOntologyRef(value: string): KnownOntologyRef {
          if (isKnownOntologyRef(value)) {
            return value;
          }
          throw new Error(`Unknown ontology reference: ${value}`);
        }

        """
    }

    private func loadJSON(path: String) throws -> JSONObject {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let object = try JSONSerialization.jsonObject(with: data) as? JSONObject else {
            throw NSError(domain: "ontologyc", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(path) is not a JSON object"])
        }
        return object
    }

    private func loadYAMLDocuments(path: String) throws -> [JSONObject] {
        let source = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
        return try source
            .components(separatedBy: "\n---")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { document -> JSONObject? in
                guard let parsed = try Yams.load(yaml: document) else { return nil }
                return parsed as? JSONObject
            }
    }

    private struct RefOccurrence {
        let ref: String
        let artifactKind: String
        let artifactId: String
    }

    private func collectRefOccurrences(_ documents: [JSONObject], namespace: String) -> [RefOccurrence] {
        var occurrences = [RefOccurrence]()
        for document in documents {
            let artifactKind = string(document["kind"]) ?? "SpecGraphArtifact"
            let artifactId = ((document["metadata"] as? JSONObject).flatMap { string($0["id"]) }) ?? "unknown"
            var refs = Set<String>()
            collectNamespaceRefs(document, namespace: namespace, refs: &refs)
            for ref in refs.sorted() {
                occurrences.append(RefOccurrence(ref: ref, artifactKind: artifactKind, artifactId: artifactId))
            }
        }
        return occurrences
    }

    private func collectNamespaceRefs(_ value: Any, namespace: String, refs: inout Set<String>) {
        if let object = value as? JSONObject {
            for key in object.keys.sorted() {
                if let child = object[key] {
                    collectNamespaceRefs(child, namespace: namespace, refs: &refs)
                }
            }
        } else if let array = value as? [Any] {
            for child in array {
                collectNamespaceRefs(child, namespace: namespace, refs: &refs)
            }
        } else if let scalar = value as? String, scalar.hasPrefix("\(namespace):") {
            refs.insert(scalar)
        }
    }

    private func collectOntologyImports(_ documents: [JSONObject]) -> [JSONObject] {
        var imports = [JSONObject]()
        for document in documents {
            collectOntologyImports(document, imports: &imports)
        }
        return imports.sorted {
            (string($0["namespace"]) ?? "") < (string($1["namespace"]) ?? "")
        }
    }

    private func collectOntologyImports(_ value: Any, imports: inout [JSONObject]) {
        if let object = value as? JSONObject {
            if let ontologyImports = object["ontologyImports"] as? [Any] {
                imports.append(contentsOf: ontologyImports.compactMap { $0 as? JSONObject })
            }
            for key in object.keys.sorted() {
                if let child = object[key] {
                    collectOntologyImports(child, imports: &imports)
                }
            }
        } else if let array = value as? [Any] {
            for child in array {
                collectOntologyImports(child, imports: &imports)
            }
        }
    }

    private func conceptRefIndex(_ ir: JSONObject) -> [String: JSONObject] {
        let ontologyId = string(ir["id"]) ?? ""
        let namespace = string(ir["namespace"]) ?? ""
        let version = string(ir["version"]) ?? ""
        var index = [String: JSONObject]()

        func addRefs(from items: [JSONObject], kind: (JSONObject) -> String, uriPrefix: String) {
            for item in items {
                guard let id = string(item["id"]) else { continue }
                let alias = "\(namespace):\(id)"
                index[alias] = [
                    "ontology": ontologyId,
                    "version": version,
                    "namespace": namespace,
                    "concept": id,
                    "kindOfConcept": kind(item),
                    "alias": alias,
                    "uri": string(item["uri"]) ?? "ontology://\(ontologyId)/\(version)/\(uriPrefix)/\(id)"
                ]
            }
        }

        addRefs(from: ir["classes"] as? [JSONObject] ?? [], kind: { self.string($0["kind"]) ?? "Class" }, uriPrefix: "classes")
        addRefs(from: ir["relations"] as? [JSONObject] ?? [], kind: { _ in "Relation" }, uriPrefix: "relations")
        addRefs(from: ir["policies"] as? [JSONObject] ?? [], kind: { _ in "Policy" }, uriPrefix: "policies")
        addRefs(from: ir["stateMachines"] as? [JSONObject] ?? [], kind: { _ in "StateMachine" }, uriPrefix: "stateMachines")
        return index
    }

    private func ontologyGap(for occurrence: RefOccurrence, ir: JSONObject, ordinal: Int) -> JSONObject {
        [
            "apiVersion": "specgraph.io/v1alpha1",
            "kind": "OntologyGap",
            "metadata": [
                "id": String(format: "gap-%03d", ordinal)
            ],
            "spec": [
                "sourceArtifact": [
                    "kind": occurrence.artifactKind,
                    "id": occurrence.artifactId
                ],
                "missingConcept": occurrence.ref,
                "targetOntology": string(ir["id"]) ?? "",
                "requestedAction": [
                    "type": "proposeOntologyDelta"
                ]
            ]
        ]
    }

    private func lockfile(imports: [JSONObject], ir: JSONObject, index: [String: JSONObject]) -> JSONObject {
        let namespace = string(ir["namespace"]) ?? ""
        let aliases = index.keys.sorted().reduce(into: JSONObject()) { output, alias in
            output[refName(alias)] = alias
        }
        let importObject = imports.first { string($0["namespace"]) == namespace }
        return [
            "apiVersion": "specgraph.io/v1alpha1",
            "kind": "OntologyLockfile",
            "metadata": [
                "project": "semantic-validation"
            ],
            "spec": [
                "resolved": [[
                    "ontology": string(importObject?["ontology"]) ?? string(ir["id"]) ?? "",
                    "namespace": namespace,
                    "version": string(importObject?["version"]) ?? string(ir["version"]) ?? "",
                    "digest": string(ir["sourceDigest"]) ?? "",
                    "registryUri": string(importObject?["source"]) ?? "",
                    "aliases": aliases
                ]]
            ]
        ]
    }

    private func compatibilityReport(fromIR: JSONObject, toIR: JSONObject) -> JSONObject {
        let fromClasses = mapById(fromIR["classes"] as? [JSONObject] ?? [])
        let toClasses = mapById(toIR["classes"] as? [JSONObject] ?? [])
        let fromRelations = mapById(fromIR["relations"] as? [JSONObject] ?? [])
        let toRelations = mapById(toIR["relations"] as? [JSONObject] ?? [])

        let addedClasses = sortedDifference(Set(toClasses.keys), Set(fromClasses.keys)).map { "\(string(toIR["namespace"]) ?? ""):\($0)" }
        let removedClasses = sortedDifference(Set(fromClasses.keys), Set(toClasses.keys)).map { "\(string(fromIR["namespace"]) ?? ""):\($0)" }
        let addedRelations = sortedDifference(Set(toRelations.keys), Set(fromRelations.keys)).map { "\(string(toIR["namespace"]) ?? ""):\($0)" }
        let removedRelations = sortedDifference(Set(fromRelations.keys), Set(toRelations.keys)).map { "\(string(fromIR["namespace"]) ?? ""):\($0)" }

        var breakingChanges = [String]()
        breakingChanges.append(contentsOf: removedClasses.map { "remove class \($0)" })
        breakingChanges.append(contentsOf: removedRelations.map { "remove relation \($0)" })

        for relationId in Set(fromRelations.keys).intersection(Set(toRelations.keys)).sorted() {
            guard let before = fromRelations[relationId], let after = toRelations[relationId] else { continue }
            if jsonComparable(before["domain"]) != jsonComparable(after["domain"]) {
                breakingChanges.append("change relation domain \(string(fromIR["namespace"]) ?? ""):\(relationId)")
            }
            if jsonComparable(before["range"]) != jsonComparable(after["range"]) {
                breakingChanges.append("change relation range \(string(fromIR["namespace"]) ?? ""):\(relationId)")
            }
        }

        return [
            "apiVersion": "ontology.specgraph.io/v1alpha1",
            "kind": "OntologyCompatibilityReport",
            "metadata": [
                "from": "\(string(fromIR["id"]) ?? "")@\(string(fromIR["version"]) ?? "")",
                "to": "\(string(toIR["id"]) ?? "")@\(string(toIR["version"]) ?? "")"
            ],
            "result": [
                "compatible": breakingChanges.isEmpty,
                "requiredSpecGraphActions": breakingChanges.isEmpty ? ["updateLockfile"] : ["reviewBreakingOntologyChange"]
            ],
            "changes": [
                "addedClasses": addedClasses,
                "addedRelations": addedRelations,
                "removedClasses": removedClasses,
                "removedRelations": removedRelations,
                "breakingChanges": breakingChanges
            ]
        ]
    }

    private func mapById(_ items: [JSONObject]) -> [String: JSONObject] {
        items.reduce(into: [String: JSONObject]()) { output, item in
            if let id = string(item["id"]) {
                output[id] = item
            }
        }
    }

    private func sortedDifference(_ lhs: Set<String>, _ rhs: Set<String>) -> [String] {
        Array(lhs.subtracting(rhs)).sorted()
    }

    private func jsonComparable(_ value: Any?) -> String {
        guard let value else { return "" }
        if !JSONSerialization.isValidJSONObject(value) {
            return String(describing: value)
        }
        return jsonText(value)
    }

    private func refLiteral(ir: JSONObject, item: JSONObject, kindKey: String? = nil, fixedKind: String? = nil) -> JSONObject {
        let id = string(item["id"]) ?? ""
        let namespace = string(ir["namespace"]) ?? ""
        let ontologyId = string(ir["id"]) ?? ""
        let version = string(ir["version"]) ?? ""
        return [
            "ontology": ontologyId,
            "version": version,
            "namespace": namespace,
            "concept": id,
            "kindOfConcept": fixedKind ?? string(item[kindKey ?? ""]) ?? "",
            "alias": "\(namespace):\(id)",
            "uri": string(item["uri"]) ?? "ontology://\(ontologyId)/\(version)/\(id)"
        ]
    }

    private func scanUnsafeSource(_ source: String, filePath: String) {
        for (lineIndex, line) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let lineText = String(line)
            if matches(lineText, unsafeTagPattern, caseInsensitive: true) ||
                unsafeValuePatterns.contains(where: { matches(lineText, $0) }) {
                add("security.executable_content", "\(filePath):\(lineIndex + 1)", "YAML contains executable-looking content")
            }
        }
    }

    private func scanUnsafeNode(_ value: Any, path: String) {
        if let object = value as? JSONObject {
            for key in object.keys.sorted() {
                if unsafeKeys.contains(key.lowercased()) {
                    add("security.executable_content", "\(path).\(key)", "YAML contains executable-looking key")
                }
                if let child = object[key] {
                    scanUnsafeNode(child, path: "\(path).\(key)")
                }
            }
        } else if let array = value as? [Any] {
            for (index, child) in array.enumerated() {
                scanUnsafeNode(child, path: "\(path)[\(index)]")
            }
        } else if let scalar = value as? String,
                  unsafeValuePatterns.contains(where: { matches(scalar, $0) }) {
            add("security.executable_content", path, "YAML contains executable-looking string")
        }
    }

    private func validateKnownKeys(_ object: JSONObject, allowed: Set<String>, path: String) {
        for key in object.keys.sorted() where !allowed.contains(key) {
            add("object.unknown_key", "\(path).\(key)", "Unknown key \(key)")
        }
    }

    private func validateKnownKeys(_ object: JSONObject, allowed: [String], path: String) {
        validateKnownKeys(object, allowed: Set(allowed), path: path)
    }

    private func requiredString(_ object: JSONObject, _ key: String, path: String, code: String) -> String? {
        guard object.keys.contains(key) else {
            add(code, path, "\(path) is required")
            return nil
        }
        guard let value = string(object[key]), !value.isEmpty else {
            add("\(code).type", path, "\(path) must be a non-empty string")
            return nil
        }
        return value
    }

    private func requiredArray(_ object: JSONObject, _ key: String, path: String, code: String) -> [Any] {
        guard object.keys.contains(key) else {
            add(code, path, "\(path) is required")
            return []
        }
        guard let value = object[key] as? [Any] else {
            add("\(code).type", path, "\(path) must be an array")
            return []
        }
        return value
    }

    private func requiredObject(_ object: JSONObject, _ key: String, path: String, code: String) -> JSONObject? {
        guard object.keys.contains(key) else {
            add(code, path, "\(path) is required")
            return nil
        }
        guard let value = object[key] as? JSONObject else {
            add("\(code).type", path, "\(path) must be an object")
            return nil
        }
        return value
    }

    private func validatePattern(_ value: String, _ pattern: String, path: String, code: String) {
        if !value.isEmpty && !matches(value, pattern) {
            add(code, path, "\(path) has invalid format")
        }
    }

    private func add(_ code: String, _ path: String, _ message: String, hint: String? = nil) {
        diagnostics.append(Diagnostic(code: code, severity: "error", path: path, message: message, hint: hint))
    }

    private func string(_ value: Any?) -> String? {
        value as? String
    }

    private func relationRangeRefs(_ value: Any) -> [String] {
        if let ref = string(value) {
            return [ref]
        }
        if let object = value as? JSONObject,
           let oneOf = object["oneOf"] as? [Any] {
            return oneOf.compactMap { string($0) }
        }
        return []
    }

    private func normalizeRange(_ value: Any?, namespace: String) -> Any {
        guard let value else { return "" }
        if let ref = string(value) {
            return normalizeRef(ref, namespace: namespace)
        }
        if let object = value as? JSONObject,
           let oneOf = object["oneOf"] as? [Any] {
            return ["oneOf": oneOf.compactMap { string($0) }.map { normalizeRef($0, namespace: namespace) }.sorted()]
        }
        return ""
    }

    private func resolves(_ ref: String, localNames: Set<String>, packageNamespace: String, importNamespaces: Set<String>) -> Bool {
        guard matches(ref, conceptPattern) else { return false }
        return isImported(ref, importNamespaces) || isLocal(ref, localNames: localNames, packageNamespace: packageNamespace)
    }

    private func isImported(_ ref: String, _ importNamespaces: Set<String>) -> Bool {
        guard let namespace = refNamespace(ref) else { return false }
        return importNamespaces.contains(namespace)
    }

    private func isLocal(_ ref: String, localNames: Set<String>, packageNamespace: String) -> Bool {
        if let namespace = refNamespace(ref) {
            return namespace == packageNamespace && localNames.contains(refName(ref))
        }
        return localNames.contains(ref)
    }

    private func isLocalTrigger(_ ref: String, names: Set<String>, packageNamespace: String) -> Bool {
        if let namespace = refNamespace(ref), namespace != packageNamespace {
            return false
        }
        return names.contains(refName(ref))
    }

    private func normalizeRef(_ ref: String, namespace: String) -> String {
        ref.contains(":") ? ref : "\(namespace):\(ref)"
    }

    private func refNamespace(_ ref: String) -> String? {
        ref.split(separator: ":", maxSplits: 1).count == 2 ? String(ref.split(separator: ":", maxSplits: 1)[0]) : nil
    }

    private func refName(_ ref: String) -> String {
        let parts = ref.split(separator: ":", maxSplits: 1)
        return String(parts.count == 2 ? parts[1] : parts[0])
    }

    private func transitionSortKey(_ transition: JSONObject) -> String {
        [
            string(transition["from"]) ?? "",
            string(transition["to"]) ?? "",
            string(transition["command"]) ?? "",
            string(transition["event"]) ?? ""
        ].joined(separator: "\u{1f}")
    }

    private func sha256(_ source: String) -> String {
        let digest = SHA256.hash(data: Data(source.utf8))
        return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
    }

    private func write(json: Any, to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        let text = String(data: data, encoding: .utf8)! + "\n"
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func writeYAML(_ object: Any, to url: URL) throws {
        let text = try Yams.dump(object: object) + "\n"
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(text: String, to url: URL) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func tsObject(_ object: JSONObject) -> String {
        jsonText(object)
    }

    private func tsArray(_ array: [Any]) -> String {
        jsonText(array)
    }

    private func jsonText(_ value: Any) -> String {
        let data = try! JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        return String(data: data, encoding: .utf8)!
    }

    private func matches(_ value: String, _ pattern: String, caseInsensitive: Bool = false) -> Bool {
        var options: String.CompareOptions = [.regularExpression]
        if caseInsensitive {
            options.insert(.caseInsensitive)
        }
        return value.range(of: pattern, options: options) != nil
    }
}

extension Array where Element == JSONObject {
    func mapValuesById(_ transform: (JSONObject) -> JSONObject) -> JSONObject {
        var output = JSONObject()
        for item in self {
            if let id = item["id"] as? String {
                output[id] = transform(item)
            }
        }
        return output
    }
}

func usage() -> Never {
    fputs("""
    Usage:
      swift run ontologyc check <package.yaml>
      swift run ontologyc compile <package.yaml> --target typescript --out <directory>
      swift run ontologyc validate-specgraph <binding.yaml> --ontology-ir <ontology.normalized.json> --out <directory>
      swift run ontologyc diff --from <old-package.yaml> --to <new-package.yaml> --out <report.yaml>

    """, stderr)
    exit(2)
}

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    usage()
}

let compiler = OntologyCompiler()

switch command {
case "check":
    guard args.count == 2 else { usage() }
    let path = args[1]
    let diagnostics = compiler.check(path: path)
    if compiler.hasErrors(diagnostics) {
        compiler.printDiagnostics(diagnostics)
        exit(1)
    }
    print("ontologyc check: PASS \(path)")

case "compile":
    guard args.count == 6 else { usage() }
    let path = args[1]
    guard args[2] == "--target", args[3] == "typescript", args[4] == "--out" else {
        usage()
    }
    let outDirectory = args[5]
    do {
        let diagnostics = try compiler.compile(path: path, outDirectory: outDirectory)
        if compiler.hasErrors(diagnostics) {
            compiler.printDiagnostics(diagnostics)
            exit(1)
        }
        print("ontologyc compile: PASS \(outDirectory)")
    } catch {
        fputs("ontologyc compile: FAIL \(error)\n", stderr)
        exit(1)
    }

case "validate-specgraph":
    guard args.count == 6 else { usage() }
    let bindingPath = args[1]
    guard args[2] == "--ontology-ir", args[4] == "--out" else {
        usage()
    }
    do {
        let result = try compiler.validateSpecGraph(bindingPath: bindingPath, ontologyIRPath: args[3], outDirectory: args[5])
        print("ontologyc validate-specgraph: PASS \(bindingPath) resolved=\(result.resolved) gaps=\(result.gaps)")
    } catch {
        fputs("ontologyc validate-specgraph: FAIL \(error)\n", stderr)
        exit(1)
    }

case "diff":
    guard args.count == 7 else { usage() }
    guard args[1] == "--from", args[3] == "--to", args[5] == "--out" else {
        usage()
    }
    do {
        let diagnostics = try compiler.diffPackages(from: args[2], to: args[4], outPath: args[6])
        if compiler.hasErrors(diagnostics) {
            compiler.printDiagnostics(diagnostics)
            exit(1)
        }
        print("ontologyc diff: PASS \(args[6])")
    } catch {
        fputs("ontologyc diff: FAIL \(error)\n", stderr)
        exit(1)
    }

default:
    usage()
}
