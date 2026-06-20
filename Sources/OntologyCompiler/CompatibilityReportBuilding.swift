import Foundation
import OntologyRules

struct CompatibilityNamespaces {
    let from: String
    let to: String
}

struct CompatibilityChangesInput {
    let fromClasses: [String: JSONObject]
    let toClasses: [String: JSONObject]
    let fromRelations: [String: JSONObject]
    let toRelations: [String: JSONObject]
    let namespaces: CompatibilityNamespaces
    let fieldChanges: CompatibilityFieldChanges
    let breakingChanges: [String]
    let decision: CompatibilityChangeDecisionSpec
    let fromApplicability: JSONObject?
    let toApplicability: JSONObject?
}

extension OntologyCompiler {
    func compatibilityBreakingRemovals(
        removedClassIds: [String],
        removedRelationIds: [String],
        fromNamespace: String,
        decision: CompatibilityChangeDecisionSpec
    ) -> [String] {
        var breakingChanges = removedClassIds.compactMap {
            breakingMessage(decision.decide(
                CompatibilityChangeContext(kind: .removedClass, namespace: fromNamespace, symbolId: $0)
            ))
        }
        breakingChanges.append(contentsOf: removedRelationIds.compactMap {
            breakingMessage(decision.decide(
                CompatibilityChangeContext(kind: .removedRelation, namespace: fromNamespace, symbolId: $0)
            ))
        })
        return breakingChanges
    }

    func relationShapeBreakingChanges(
        fromRelations: [String: JSONObject],
        toRelations: [String: JSONObject],
        fromNamespace: String,
        decision: CompatibilityChangeDecisionSpec
    ) -> [String] {
        var breakingChanges = [String]()
        for relationId in Set(fromRelations.keys).intersection(Set(toRelations.keys)).sorted() {
            guard let before = fromRelations[relationId], let after = toRelations[relationId] else { continue }
            appendRelationShapeBreakingChanges(
                relationId: relationId,
                before: before,
                after: after,
                fromNamespace: fromNamespace,
                decision: decision,
                breakingChanges: &breakingChanges
            )
        }
        return breakingChanges
    }

    func compatibilityChanges(_ input: CompatibilityChangesInput) -> JSONObject {
        var changes: JSONObject = [
            "addedClasses": sortedDifference(Set(input.toClasses.keys), Set(input.fromClasses.keys)).map { "\(input.namespaces.to):\($0)" },
            "addedFields": input.fieldChanges.addedFields,
            "addedRelations": sortedDifference(Set(input.toRelations.keys), Set(input.fromRelations.keys)).map { "\(input.namespaces.to):\($0)" },
            "changedFields": input.fieldChanges.changedFields,
            "removedClasses": sortedDifference(Set(input.fromClasses.keys), Set(input.toClasses.keys)).map { "\(input.namespaces.from):\($0)" },
            "removedFields": input.fieldChanges.removedFields,
            "removedRelations": sortedDifference(Set(input.fromRelations.keys), Set(input.toRelations.keys)).map { "\(input.namespaces.from):\($0)" },
            "breakingChanges": input.breakingChanges
        ]
        let layerChanges = compatibilityLayerChanges(
            fromClasses: input.fromClasses,
            toClasses: input.toClasses,
            fromRelations: input.fromRelations,
            toRelations: input.toRelations,
            fromNamespace: input.namespaces.from,
            decision: input.decision
        )
        if !layerChanges.isEmpty {
            changes["layerChanges"] = layerChanges
        }
        changes["changeClassification"] = compatibilityChangeClassification(input: input, layerChanges: layerChanges)
        return changes
    }

    func compatibilityReportPayload(
        fromIR: JSONObject,
        toIR: JSONObject,
        breakingChanges: [String],
        changes: JSONObject
    ) -> JSONObject {
        [
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
            "changes": changes
        ]
    }

    private func appendRelationShapeBreakingChanges(
        relationId: String,
        before: JSONObject,
        after: JSONObject,
        fromNamespace: String,
        decision: CompatibilityChangeDecisionSpec,
        breakingChanges: inout [String]
    ) {
        if let domainMessage = breakingMessage(decision.decide(CompatibilityChangeContext(
            kind: .relationDomainChanged,
            namespace: fromNamespace,
            symbolId: relationId,
            beforeComparable: jsonComparable(before["domain"]),
            afterComparable: jsonComparable(after["domain"])
        ))) {
            breakingChanges.append(domainMessage)
        }
        if let rangeMessage = breakingMessage(decision.decide(CompatibilityChangeContext(
            kind: .relationRangeChanged,
            namespace: fromNamespace,
            symbolId: relationId,
            beforeComparable: jsonComparable(before["range"]),
            afterComparable: jsonComparable(after["range"])
        ))) {
            breakingChanges.append(rangeMessage)
        }
    }
}
