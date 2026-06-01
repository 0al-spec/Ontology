import Foundation
import OntologyRules

extension OntologyCompiler {
    func compatibilityReport(fromIR: JSONObject, toIR: JSONObject) -> JSONObject {
        let fromClasses = mapById(fromIR["classes"] as? [JSONObject] ?? [])
        let toClasses = mapById(toIR["classes"] as? [JSONObject] ?? [])
        let fromRelations = mapById(fromIR["relations"] as? [JSONObject] ?? [])
        let toRelations = mapById(toIR["relations"] as? [JSONObject] ?? [])

        let fromNamespace = string(fromIR["namespace"]) ?? ""
        let toNamespace = string(toIR["namespace"]) ?? ""
        let addedClassIds = sortedDifference(Set(toClasses.keys), Set(fromClasses.keys))
        let removedClassIds = sortedDifference(Set(fromClasses.keys), Set(toClasses.keys))
        let addedRelationIds = sortedDifference(Set(toRelations.keys), Set(fromRelations.keys))
        let removedRelationIds = sortedDifference(Set(fromRelations.keys), Set(toRelations.keys))
        let addedClasses = addedClassIds.map { "\(toNamespace):\($0)" }
        let removedClasses = removedClassIds.map { "\(fromNamespace):\($0)" }
        let addedRelations = addedRelationIds.map { "\(toNamespace):\($0)" }
        let removedRelations = removedRelationIds.map { "\(fromNamespace):\($0)" }

        var breakingChanges = [String]()
        let compatibilityDecision = CompatibilityChangeDecisionSpec()
        breakingChanges.append(contentsOf: removedClassIds.compactMap {
            breakingMessage(compatibilityDecision.decide(
                CompatibilityChangeContext(kind: .removedClass, namespace: fromNamespace, symbolId: $0)
            ))
        })
        breakingChanges.append(contentsOf: removedRelationIds.compactMap {
            breakingMessage(compatibilityDecision.decide(
                CompatibilityChangeContext(kind: .removedRelation, namespace: fromNamespace, symbolId: $0)
            ))
        })

        for relationId in Set(fromRelations.keys).intersection(Set(toRelations.keys)).sorted() {
            guard let before = fromRelations[relationId], let after = toRelations[relationId] else { continue }
            if let domainMessage = breakingMessage(compatibilityDecision.decide(CompatibilityChangeContext(
                kind: .relationDomainChanged,
                namespace: fromNamespace,
                symbolId: relationId,
                beforeComparable: jsonComparable(before["domain"]),
                afterComparable: jsonComparable(after["domain"])
            ))) {
                breakingChanges.append(domainMessage)
            }
            if let rangeMessage = breakingMessage(compatibilityDecision.decide(CompatibilityChangeContext(
                kind: .relationRangeChanged,
                namespace: fromNamespace,
                symbolId: relationId,
                beforeComparable: jsonComparable(before["range"]),
                afterComparable: jsonComparable(after["range"])
            ))) {
                breakingChanges.append(rangeMessage)
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

    func breakingMessage(_ decision: CompatibilityChangeDecision?) -> String? {
        guard case .breaking(let message) = decision else { return nil }
        return message
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
