import Foundation

/// Full diagrams load all declarations of explicitly supplied reachable imports, without fetching.
struct DiagramFullProjection {
    let root: JSONObject
    let imported: [DiagramImportedPackage]

    func select() throws -> JSONObject {
        guard !imported.isEmpty else { return root }
        var result = root
        for section in ["classes", "relations", "protocols", "policies", "stateMachines"] {
            var records = root[section] as? [JSONObject] ?? []
            for package in imported.sorted(by: { $0.namespace < $1.namespace }) {
                records += try package.fullDeclarations(section)
            }
            result[section] = records.sorted { ($0["fqid"] as? String ?? "") < ($1["fqid"] as? String ?? "") }
        }
        return result
    }
}

extension DiagramImportedPackage {
    func scopedReference(_ value: String) throws -> String {
        guard !value.isEmpty else { return value }
        let qualified = value.contains(":") ? value : "\(ir["namespace"] as? String ?? ""):\(value)"
        guard let mapped = rebase(qualified) else {
            throw OntologyCompilerError.invalidArgument(
                "Cannot bind imported reference \(qualified) from \(ir["id"] as? String ?? ""); check dependency identity, version and namespace bindings"
            )
        }
        return mapped
    }

    func scopedTransitions(_ transitions: [JSONObject]) throws -> [JSONObject] {
        try transitions.map { transition in
            var mapped = transition
            for key in ["command", "event"] {
                if let ref = transition[key] as? String { mapped[key] = try scopedReference(ref) }
            }
            return mapped
        }
    }

    func scopedFields(_ fields: [JSONObject]) throws -> [JSONObject] {
        try fields.map { field in
            var mapped = field
            if let target = field["target"] as? String { mapped["target"] = try scopedReference(target) }
            return mapped
        }
    }

    func fullDeclarations(_ section: String, matching selected: Set<String>? = nil) throws -> [JSONObject] {
        try (ir[section] as? [JSONObject] ?? []).filter { definition in
            selected?.contains("\(namespace):\(definition["id"] as? String ?? "")") ?? true
        }.map { definition in
            var result = definition
            result["fqid"] = "\(namespace):\(definition["id"] as? String ?? "")"
            result["diagramOrigin"] = "\(ir["id"] as? String ?? "")@\(ir["version"] as? String ?? "")"
            for key in ["extends", "domain", "action", "lifecycle"] {
                if let value = definition[key] as? String { result[key] = try scopedReference(value) }
            }
            for key in ["implements", "appliesTo", "requiredRelations"] {
                if let values = definition[key] as? [String] { result[key] = try values.map(scopedReference) }
            }
            if let range = definition["range"] as? String {
                result["range"] = try scopedReference(range)
            } else if let range = definition["range"] as? JSONObject, let alternatives = range["oneOf"] as? [String] {
                result["range"] = ["oneOf": try alternatives.map(scopedReference)]
            }
            if let transitions = definition["transitions"] as? [JSONObject] {
                result["transitions"] = try scopedTransitions(transitions)
            }
            if section == "classes", let fields = definition["fields"] as? [JSONObject] {
                result["fields"] = try scopedFields(fields)
            }
            if section == "relations" { result["id"] = result["fqid"] }
            return result
        }
    }
}
