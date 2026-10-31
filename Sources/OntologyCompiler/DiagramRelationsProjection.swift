import Foundation
import OntologyRules

struct DiagramImportedPackage {
    let namespace: String
    let ir: JSONObject
    let namespaces: [String: String]

    init(namespace: String, ir: JSONObject, root: JSONObject) throws {
        self.namespace = namespace
        self.ir = ir
        var namespaces = [ir["namespace"] as? String ?? "": namespace]
        let scope = DiagramImportBindingContext(packageId: ir["id"] as? String ?? "", version: ir["version"] as? String ?? "",
                                              rootNamespace: ir["namespace"] as? String ?? "", imports: diagramImports(ir))
        guard DiagramImportScopeSpec().isSatisfiedBy(scope) else {
            throw OntologyCompilerError.invalidArgument("Ambiguous namespace scope in supplied package \(scope.packageId.rawValue)")
        }
        for dependency in diagramImports(ir) {
            if dependency.id.rawValue == root["id"] as? String, dependency.version.rawValue == root["version"] as? String {
                namespaces[dependency.namespace.rawValue] = root["namespace"] as? String
                continue
            }
            let context = DiagramImportBindingContext(
                packageId: dependency.id.rawValue, version: dependency.version.rawValue,
                rootNamespace: root["namespace"] as? String ?? "", imports: diagramImports(root)
            )
            if case .matched(let alias) = DiagramImportBindingSpec().decide(context) {
                namespaces[dependency.namespace.rawValue] = alias
            }
        }
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

    func relations(visible: Set<String>) -> [JSONObject] {
        (ir["relations"] as? [JSONObject] ?? []).compactMap { definition in
            let ranges = diagramRangeReferences(definition["range"])
            let targets = ranges.compactMap(rebase)
            guard !targets.isEmpty, targets.count == ranges.count,
                  let domain = rebase(definition["domain"] as? String ?? ""),
                  visible.contains(domain), targets.allSatisfy(visible.contains) else { return nil }
            var result = definition
            result["domain"] = domain
            result["range"] = definition["range"] is String ? targets[0] : ["oneOf": targets]
            result["id"] = "\(namespace):\(definition["id"] as? String ?? "")"
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
        let relations = (root["relations"] as? [JSONObject] ?? []) + imported.flatMap { $0.relations(visible: visible) }
        let incident = Set(relations.flatMap { [$0["domain"] as? String ?? ""] + diagramRangeReferences($0["range"]) })
        var result = root
        result["classes"] = (rootClasses.filter { incident.contains($0["fqid"] as? String ?? "") }
            + importedClasses.filter { selected.contains($0["fqid"] as? String ?? "") })
            .sorted { ($0["fqid"] as? String ?? "") < ($1["fqid"] as? String ?? "") }
        result["relations"] = relations
        return result
    }
}
