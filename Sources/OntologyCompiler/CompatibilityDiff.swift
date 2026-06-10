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

        let fieldChanges = compatibilityFieldChanges(
            fromClasses: fromClasses,
            toClasses: toClasses,
            fromNamespace: fromNamespace,
            toNamespace: toNamespace,
            decision: compatibilityDecision
        )
        breakingChanges.append(contentsOf: fieldChanges.breakingChanges)

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
                "addedFields": fieldChanges.addedFields,
                "addedRelations": addedRelations,
                "changedFields": fieldChanges.changedFields,
                "removedClasses": removedClasses,
                "removedFields": fieldChanges.removedFields,
                "removedRelations": removedRelations,
                "breakingChanges": breakingChanges
            ]
        ]
    }

    func compatibilityFieldChanges(
        fromClasses: [String: JSONObject],
        toClasses: [String: JSONObject],
        fromNamespace: String,
        toNamespace: String,
        decision: CompatibilityChangeDecisionSpec
    ) -> CompatibilityFieldChanges {
        var changes = CompatibilityFieldChanges()
        for classId in Set(fromClasses.keys).intersection(Set(toClasses.keys)).sorted() {
            guard let beforeClass = fromClasses[classId], let afterClass = toClasses[classId] else { continue }
            changes.append(classFieldChanges(
                classId: classId,
                beforeClass: beforeClass,
                afterClass: afterClass,
                fromNamespace: fromNamespace,
                toNamespace: toNamespace,
                decision: decision
            ))
        }
        return changes
    }

    func classFieldChanges(
        classId: String,
        beforeClass: JSONObject,
        afterClass: JSONObject,
        fromNamespace: String,
        toNamespace: String,
        decision: CompatibilityChangeDecisionSpec
    ) -> CompatibilityFieldChanges {
        let beforeFields = mapById(compatClassFields(beforeClass))
        let afterFields = mapById(compatClassFields(afterClass))
        var changes = CompatibilityFieldChanges()

        changes.append(addedClassFieldChanges(
            classId: classId,
            fieldIds: sortedDifference(Set(afterFields.keys), Set(beforeFields.keys)),
            fields: afterFields,
            toNamespace: toNamespace,
            decision: decision
        ))
        changes.append(removedClassFieldChanges(
            classId: classId,
            fieldIds: sortedDifference(Set(beforeFields.keys), Set(afterFields.keys)),
            fromNamespace: fromNamespace,
            decision: decision
        ))

        for fieldId in Set(beforeFields.keys).intersection(Set(afterFields.keys)).sorted() {
            guard let beforeField = beforeFields[fieldId], let afterField = afterFields[fieldId] else { continue }
            changes.append(changedClassFieldChanges(
                classId: classId,
                fieldId: fieldId,
                beforeField: beforeField,
                afterField: afterField,
                fromNamespace: fromNamespace,
                decision: decision
            ))
        }
        return changes
    }

    func addedClassFieldChanges(
        classId: String,
        fieldIds: [String],
        fields: [String: JSONObject],
        toNamespace: String,
        decision: CompatibilityChangeDecisionSpec
    ) -> CompatibilityFieldChanges {
        var changes = CompatibilityFieldChanges()
        for fieldId in fieldIds {
            let symbolId = "\(classId).\(fieldId)"
            changes.addedFields.append("\(toNamespace):\(symbolId)")
            if (fields[fieldId]?["required"] as? Bool) == true,
               let message = breakingMessage(decision.decide(CompatibilityChangeContext(
                   kind: .classRequiredFieldAdded,
                   namespace: toNamespace,
                   symbolId: symbolId
               ))) {
                changes.breakingChanges.append(message)
            }
        }
        return changes
    }

    func removedClassFieldChanges(
        classId: String,
        fieldIds: [String],
        fromNamespace: String,
        decision: CompatibilityChangeDecisionSpec
    ) -> CompatibilityFieldChanges {
        var changes = CompatibilityFieldChanges()
        for fieldId in fieldIds {
            let symbolId = "\(classId).\(fieldId)"
            changes.removedFields.append("\(fromNamespace):\(symbolId)")
            if let message = breakingMessage(decision.decide(CompatibilityChangeContext(
                kind: .classFieldRemoved,
                namespace: fromNamespace,
                symbolId: symbolId
            ))) {
                changes.breakingChanges.append(message)
            }
        }
        return changes
    }

    func changedClassFieldChanges(
        classId: String,
        fieldId: String,
        beforeField: JSONObject,
        afterField: JSONObject,
        fromNamespace: String,
        decision: CompatibilityChangeDecisionSpec
    ) -> CompatibilityFieldChanges {
        let symbolId = "\(classId).\(fieldId)"
        var changes = CompatibilityFieldChanges()
        appendTypeChange(
            symbolId: symbolId,
            beforeField: beforeField,
            afterField: afterField,
            fromNamespace: fromNamespace,
            decision: decision,
            changes: &changes
        )
        appendRequirednessChange(
            symbolId: symbolId,
            beforeField: beforeField,
            afterField: afterField,
            fromNamespace: fromNamespace,
            decision: decision,
            changes: &changes
        )
        return changes
    }

    func appendTypeChange(
        symbolId: String,
        beforeField: JSONObject,
        afterField: JSONObject,
        fromNamespace: String,
        decision: CompatibilityChangeDecisionSpec,
        changes: inout CompatibilityFieldChanges
    ) {
        let beforeType = string(beforeField["type"]) ?? ""
        let afterType = string(afterField["type"]) ?? ""
        guard beforeType != afterType else { return }
        changes.changedFields.append("\(fromNamespace):\(symbolId)")
        if let message = breakingMessage(decision.decide(CompatibilityChangeContext(
            kind: .classFieldTypeChanged,
            namespace: fromNamespace,
            symbolId: symbolId,
            beforeComparable: beforeType,
            afterComparable: afterType
        ))) {
            changes.breakingChanges.append(message)
        }
    }

    func appendRequirednessChange(
        symbolId: String,
        beforeField: JSONObject,
        afterField: JSONObject,
        fromNamespace: String,
        decision: CompatibilityChangeDecisionSpec,
        changes: inout CompatibilityFieldChanges
    ) {
        let beforeRequired = ((beforeField["required"] as? Bool) ?? false).description
        let afterRequired = ((afterField["required"] as? Bool) ?? false).description
        guard beforeRequired != afterRequired else { return }
        let fieldRef = "\(fromNamespace):\(symbolId)"
        if !changes.changedFields.contains(fieldRef) {
            changes.changedFields.append(fieldRef)
        }
        if let message = breakingMessage(decision.decide(CompatibilityChangeContext(
            kind: .classFieldRequirednessChanged,
            namespace: fromNamespace,
            symbolId: symbolId,
            beforeComparable: beforeRequired,
            afterComparable: afterRequired
        ))) {
            changes.breakingChanges.append(message)
        }
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

    func compatClassFields(_ item: JSONObject) -> [JSONObject] {
        (item["fields"] as? [Any] ?? []).compactMap { $0 as? JSONObject }
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

struct CompatibilityFieldChanges {
    var addedFields = [String]()
    var removedFields = [String]()
    var changedFields = [String]()
    var breakingChanges = [String]()

    mutating func append(_ changes: CompatibilityFieldChanges) {
        addedFields.append(contentsOf: changes.addedFields)
        removedFields.append(contentsOf: changes.removedFields)
        changedFields.append(contentsOf: changes.changedFields)
        breakingChanges.append(contentsOf: changes.breakingChanges)
    }
}
