import Foundation

extension OntologyCompiler {
    func normalize(_ package: LoadedPackage) -> JSONObject {
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
        let protocolsObject = spec["protocols"] as? JSONObject ?? [:]
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

        let protocols = protocolsObject.keys.sorted().map { name -> JSONObject in
            let definition = protocolsObject[name] as? JSONObject ?? [:]
            var normalized: JSONObject = [
                "id": name,
                "fqid": "\(package.namespace):\(name)",
                "uri": "ontology://\(package.id)/\(package.version)/protocols/\(name)",
                "description": string(definition["description"]) ?? ""
            ]
            let requiredFields = (definition["requiredFields"] as? [Any] ?? []).compactMap { string($0) }.sorted()
            if !requiredFields.isEmpty { normalized["requiredFields"] = requiredFields }
            let requiredRelations = (definition["requiredRelations"] as? [Any] ?? []).compactMap { string($0) }.sorted()
            if !requiredRelations.isEmpty { normalized["requiredRelations"] = requiredRelations }
            return normalized
        }

        var ir: JSONObject = [
            "id": package.id,
            "namespace": package.namespace,
            "version": package.version,
            "sourceDigest": sha256(package.source),
            "imports": imports,
            "classes": classes,
            "relations": relations,
            "protocols": protocols,
            "policies": policies,
            "stateMachines": stateMachines,
            "diagnostics": []
        ]
        if let compatibility = spec["compatibility"] as? JSONObject {
            ir["compatibility"] = compatibility
        }
        return ir
    }
}
