import Foundation
import OntologyRules

struct DiagramImportedPackage {
    let namespace: String
    let ir: JSONObject
    let namespaces: [String: String]

    init(namespace: String, ir: JSONObject, namespaces: [String: String]) {
        self.namespace = namespace
        self.ir = ir
        self.namespaces = namespaces
    }

    func rebase(_ ref: String) -> String? {
        let parts = ref.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let alias = namespaces[parts[0]] else { return nil }
        return "\(alias):\(parts[1])"
    }

    var classes: [JSONObject] {
        (ir["classes"] as? [JSONObject] ?? []).map { definition in
            var result = definition
            result["fqid"] = "\(namespace):\(definition["id"] as? String ?? "")"
            result["diagramOrigin"] = "\(ir["id"] as? String ?? "")@\(ir["version"] as? String ?? "")"
            return result
        }
    }

    func relations(visible: Set<String>) throws -> [JSONObject] {
        try (ir["relations"] as? [JSONObject] ?? []).compactMap { definition in
            let ranges = diagramRangeReferences(definition["range"])
            let targets = ranges.compactMap(rebase)
            guard !targets.isEmpty, targets.count == ranges.count,
                  let domain = rebase(definition["domain"] as? String ?? ""),
                  visible.contains(domain), targets.allSatisfy(visible.contains) else { return nil }
            var result = definition
            if let action = definition["action"] as? String {
                result["action"] = try scopedReference(action)
            }
            result["domain"] = domain
            result["range"] = definition["range"] is String ? targets[0] : ["oneOf": targets]
            result["id"] = "\(namespace):\(definition["id"] as? String ?? "")"
            result["fqid"] = result["id"]
            return result
        }
    }
}

struct DiagramRelationsProjection {
    let root: JSONObject
    let imported: [DiagramImportedPackage]

    func select(_ selectors: [String]) throws -> JSONObject {
        let selected = Set(selectors)
        let importedClasses = imported.flatMap(\.classes)
        let available = Set(importedClasses.compactMap { $0["fqid"] as? String })
        let missing = selected.subtracting(available).sorted()
        guard missing.isEmpty else {
            throw OntologyCompilerError.invalidArgument("Expanded classes are not declared in supplied imports: \(missing.joined(separator: ", "))")
        }
        let rootClasses = root["classes"] as? [JSONObject] ?? []
        let visible = Set(rootClasses.compactMap { $0["fqid"] as? String }).union(selected)
        let relations = try (root["relations"] as? [JSONObject] ?? [])
            + imported.sorted { $0.namespace < $1.namespace }.flatMap { try $0.relations(visible: visible) }
        let incident = Set(relations.flatMap { definition in
            [definition["domain"], definition["action"]].compactMap { $0 as? String } + diagramRangeReferences(definition["range"])
        })
        var result = root
        let selectedImported = try imported.flatMap { try $0.fullDeclarations("classes", matching: selected) }
        result["classes"] = (rootClasses.filter { incident.contains($0["fqid"] as? String ?? "") } + selectedImported)
            .sorted { ($0["fqid"] as? String ?? "") < ($1["fqid"] as? String ?? "") }
        result["relations"] = relations
        return result
    }
}
