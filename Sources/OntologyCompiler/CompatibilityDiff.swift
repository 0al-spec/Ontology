import Foundation

extension OntologyCompiler {
    func compatibilityReport(fromIR: JSONObject, toIR: JSONObject) -> JSONObject {
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

    func mapById(_ items: [JSONObject]) -> [String: JSONObject] {
        items.reduce(into: [String: JSONObject]()) { output, item in
            if let id = string(item["id"]) {
                output[id] = item
            }
        }
    }

    func sortedDifference(_ lhs: Set<String>, _ rhs: Set<String>) -> [String] {
        Array(lhs.subtracting(rhs)).sorted()
    }

    func jsonComparable(_ value: Any?) -> String {
        guard let value else { return "" }
        if !JSONSerialization.isValidJSONObject(value) {
            return String(describing: value)
        }
        return jsonText(value)
    }

    func refLiteral(ir: JSONObject, item: JSONObject, kindKey: String? = nil, fixedKind: String? = nil) -> JSONObject {
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
}
