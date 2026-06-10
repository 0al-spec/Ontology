import Foundation

extension OntologyCompiler {
    func normalize(_ package: LoadedPackage) -> JSONObject {
        let spec = package.spec
        var ir: JSONObject = [
            "id": package.id,
            "namespace": package.namespace,
            "version": package.version,
            "sourceDigest": sha256(package.source),
            "imports": normalizeImports(spec),
            "classes": normalizeClasses(spec, package: package),
            "relations": normalizeRelations(spec, package: package),
            "protocols": normalizeProtocols(spec, package: package),
            "policies": normalizePolicies(spec, package: package),
            "stateMachines": normalizeStateMachines(spec, package: package),
            "diagnostics": []
        ]
        if let compatibility = spec["compatibility"] as? JSONObject {
            ir["compatibility"] = compatibility
        }
        return ir
    }

    private func normalizeImports(_ spec: JSONObject) -> [JSONObject] {
        (spec["imports"] as? [Any] ?? []).compactMap { $0 as? JSONObject }
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
    }

    private func normalizeClasses(_ spec: JSONObject, package: LoadedPackage) -> [JSONObject] {
        let classesObject = spec["classes"] as? JSONObject ?? [:]
        return classesObject.keys.sorted().map { name -> JSONObject in
            let definition = classesObject[name] as? JSONObject ?? [:]
            let extends = string(definition["extends"]) ?? ""
            var normalized: JSONObject = [
                "id": name,
                "fqid": "\(package.namespace):\(name)",
                "uri": "ontology://\(package.id)/\(package.version)/classes/\(name)",
                "kind": refName(extends),
                "extends": normalizeRef(extends, namespace: package.namespace),
                "implements": normalizedRefs(definition["implements"], namespace: package.namespace),
                "description": string(definition["description"]) ?? "",
                "central": (definition["central"] as? Bool) ?? false,
                "aliases": (definition["aliases"] as? [Any] ?? []).compactMap { string($0) }.sorted()
            ]
            if let lifecycle = string(definition["lifecycle"]) {
                normalized["lifecycle"] = lifecycle
            }
            let fields = normalizeFields(definition["fields"])
            if !fields.isEmpty {
                normalized["fields"] = fields
            }
            return normalized
        }
    }

    private func normalizeFields(_ value: Any?) -> [JSONObject] {
        guard let fieldsObject = value as? JSONObject else { return [] }
        return fieldsObject.keys.sorted().map { name -> JSONObject in
            let definition = fieldsObject[name] as? JSONObject ?? [:]
            var normalized: JSONObject = [
                "id": name,
                "type": string(definition["type"]) ?? "",
                "required": (definition["required"] as? Bool) ?? false
            ]
            if let description = string(definition["description"]) {
                normalized["description"] = description
            }
            return normalized
        }
    }

    private func normalizeRelations(_ spec: JSONObject, package: LoadedPackage) -> [JSONObject] {
        let relationsObject = spec["relations"] as? JSONObject ?? [:]
        return relationsObject.keys.sorted().map { name -> JSONObject in
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
    }

    private func normalizePolicies(_ spec: JSONObject, package: LoadedPackage) -> [JSONObject] {
        let policiesObject = spec["policies"] as? JSONObject ?? [:]
        return policiesObject.keys.sorted().map { name -> JSONObject in
            let definition = policiesObject[name] as? JSONObject ?? [:]
            return [
                "id": name,
                "fqid": "\(package.namespace):\(name)",
                "extends": normalizeRef(string(definition["extends"]) ?? "", namespace: package.namespace),
                "enforceability": string(definition["enforceability"]) ?? "",
                "appliesTo": normalizedRefs(definition["appliesTo"], namespace: package.namespace),
                "text": string(definition["text"]) ?? ""
            ]
        }
    }

    private func normalizeStateMachines(_ spec: JSONObject, package: LoadedPackage) -> [JSONObject] {
        let stateMachinesObject = spec["stateMachines"] as? JSONObject ?? [:]
        return stateMachinesObject.keys.sorted().map { name -> JSONObject in
            let definition = stateMachinesObject[name] as? JSONObject ?? [:]
            return [
                "id": name,
                "fqid": "\(package.namespace):\(name)",
                "states": (definition["states"] as? [Any] ?? []).compactMap { string($0) }.sorted(),
                "transitions": normalizeTransitions(definition, namespace: package.namespace)
            ]
        }
    }

    private func normalizeTransitions(_ definition: JSONObject, namespace: String) -> [JSONObject] {
        (definition["transitions"] as? [Any] ?? []).compactMap { $0 as? JSONObject }
            .map { transition -> JSONObject in
                var normalized: JSONObject = [
                    "from": string(transition["from"]) ?? "",
                    "to": string(transition["to"]) ?? ""
                ]
                if let command = string(transition["command"]) {
                    normalized["command"] = normalizeRef(command, namespace: namespace)
                }
                if let event = string(transition["event"]) {
                    normalized["event"] = normalizeRef(event, namespace: namespace)
                }
                return normalized
            }
            .sorted { transitionSortKey($0) < transitionSortKey($1) }
    }

    private func normalizeProtocols(_ spec: JSONObject, package: LoadedPackage) -> [JSONObject] {
        let protocolsObject = spec["protocols"] as? JSONObject ?? [:]
        return protocolsObject.keys.sorted().map { name -> JSONObject in
            let definition = protocolsObject[name] as? JSONObject ?? [:]
            var normalized: JSONObject = [
                "id": name,
                "fqid": "\(package.namespace):\(name)",
                "uri": "ontology://\(package.id)/\(package.version)/protocols/\(name)",
                "description": string(definition["description"]) ?? ""
            ]
            let requiredFields = sortedStrings(definition["requiredFields"])
            if !requiredFields.isEmpty { normalized["requiredFields"] = requiredFields }
            let requiredRelations = sortedStrings(definition["requiredRelations"])
            if !requiredRelations.isEmpty { normalized["requiredRelations"] = requiredRelations }
            return normalized
        }
    }

    private func normalizedRefs(_ value: Any?, namespace: String) -> [String] {
        (value as? [Any] ?? []).compactMap { string($0) }.map { normalizeRef($0, namespace: namespace) }.sorted()
    }

    private func sortedStrings(_ value: Any?) -> [String] {
        (value as? [Any] ?? []).compactMap { string($0) }.sorted()
    }
}
