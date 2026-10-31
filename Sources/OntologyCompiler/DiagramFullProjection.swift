import Foundation

/// Full diagrams load all declarations of explicit direct imports, without fetching.
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
    private func fullReference(_ value: String) throws -> String {
        guard !value.isEmpty else { return value }
        let qualified = value.contains(":") ? value : "\(ir["namespace"] as? String ?? ""):\(value)"
        guard let mapped = rebase(qualified) else {
            throw OntologyCompilerError.invalidArgument(
                "Cannot bind imported reference \(qualified) from \(ir["id"] as? String ?? ""); declare its dependency in the root scope"
            )
        }
        return mapped
    }

    func fullDeclarations(_ section: String) throws -> [JSONObject] {
        try (ir[section] as? [JSONObject] ?? []).map { definition in
            var result = definition
            result["fqid"] = "\(namespace):\(definition["id"] as? String ?? "")"
            result["diagramOrigin"] = "\(ir["id"] as? String ?? "")@\(ir["version"] as? String ?? "")"
            for key in ["extends", "domain", "lifecycle"] {
                if let value = definition[key] as? String { result[key] = try fullReference(value) }
            }
            for key in ["implements", "appliesTo", "requiredRelations"] {
                if let values = definition[key] as? [String] { result[key] = try values.map(fullReference) }
            }
            if let range = definition["range"] as? String {
                result["range"] = try fullReference(range)
            } else if let range = definition["range"] as? JSONObject, let alternatives = range["oneOf"] as? [String] {
                result["range"] = ["oneOf": try alternatives.map(fullReference)]
            }
            if let transitions = definition["transitions"] as? [JSONObject] {
                result["transitions"] = try transitions.map { transition in
                    var mapped = transition
                    for key in ["command", "event"] {
                        if let ref = transition[key] as? String { mapped[key] = try fullReference(ref) }
                    }
                    return mapped
                }
            }
            if section == "relations" { result["id"] = result["fqid"] }
            return result
        }
    }
}
