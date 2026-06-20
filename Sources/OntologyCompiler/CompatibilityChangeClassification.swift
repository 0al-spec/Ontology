import Foundation

extension OntologyCompiler {
    func compatibilityChangeClassification(input: CompatibilityChangesInput, layerChanges: [JSONObject]) -> JSONObject {
        [
            "structuralChanges": structuralChangeClassification(input),
            "annotationChanges": annotationChangeClassification(layerChanges),
            "applicabilityChanges": applicabilityChangeClassification(
                from: input.fromApplicability,
                to: input.toApplicability
            )
        ]
    }

    private func structuralChangeClassification(_ input: CompatibilityChangesInput) -> [JSONObject] {
        var changes = [JSONObject]()
        appendRefChanges(
            to: &changes,
            kind: "classAdded",
            refs: sortedDifference(Set(input.toClasses.keys), Set(input.fromClasses.keys)).map { "\(input.namespaces.to):\($0)" }
        )
        appendRefChanges(
            to: &changes,
            kind: "classRemoved",
            refs: sortedDifference(Set(input.fromClasses.keys), Set(input.toClasses.keys)).map { "\(input.namespaces.from):\($0)" }
        )
        appendRefChanges(to: &changes, kind: "fieldAdded", refs: input.fieldChanges.addedFields)
        appendRefChanges(to: &changes, kind: "fieldRemoved", refs: input.fieldChanges.removedFields)
        appendRefChanges(to: &changes, kind: "fieldChanged", refs: input.fieldChanges.changedFields)
        appendRefChanges(
            to: &changes,
            kind: "relationAdded",
            refs: sortedDifference(Set(input.toRelations.keys), Set(input.fromRelations.keys)).map { "\(input.namespaces.to):\($0)" }
        )
        appendRefChanges(
            to: &changes,
            kind: "relationRemoved",
            refs: sortedDifference(Set(input.fromRelations.keys), Set(input.toRelations.keys)).map { "\(input.namespaces.from):\($0)" }
        )
        appendRelationShapeClassifications(to: &changes, input: input)
        return changes
    }

    private func appendRelationShapeClassifications(to changes: inout [JSONObject], input: CompatibilityChangesInput) {
        for relationId in Set(input.fromRelations.keys).intersection(Set(input.toRelations.keys)).sorted() {
            guard let before = input.fromRelations[relationId], let after = input.toRelations[relationId] else { continue }
            appendComparableChange(
                to: &changes,
                kind: "relationDomainChanged",
                ref: "\(input.namespaces.from):\(relationId)",
                before: before["domain"],
                after: after["domain"]
            )
            appendComparableChange(
                to: &changes,
                kind: "relationRangeChanged",
                ref: "\(input.namespaces.from):\(relationId)",
                before: before["range"],
                after: after["range"]
            )
        }
    }

    private func annotationChangeClassification(_ layerChanges: [JSONObject]) -> [JSONObject] {
        layerChanges.map { change in
            var output: JSONObject = [
                "kind": string(change["classification"]) ?? "layerChanged",
                "ref": string(change["symbol"]) ?? "",
                "targetKind": string(change["kind"]) ?? ""
            ]
            if let before = string(change["before"]), !before.isEmpty {
                output["before"] = before
            }
            if let after = string(change["after"]), !after.isEmpty {
                output["after"] = after
            }
            if let compatibility = string(change["compatibility"]) {
                output["compatibility"] = compatibility
            }
            return output
        }
    }

    private func applicabilityChangeClassification(from: JSONObject?, to: JSONObject?) -> [JSONObject] {
        if from == nil, to == nil { return [] }
        if jsonComparable(from) == jsonComparable(to) { return [] }
        guard let from, let to else {
            return [[
                "kind": from == nil ? "modelApplicabilityAdded" : "modelApplicabilityRemoved",
                "ref": "modelApplicability"
            ]]
        }

        var changes = [JSONObject]()
        appendComparableChange(
            to: &changes,
            kind: "appliesToChanged",
            ref: "modelApplicability.appliesTo",
            before: from["appliesTo"],
            after: to["appliesTo"]
        )
        appendComparableChange(
            to: &changes,
            kind: "excludesChanged",
            ref: "modelApplicability.excludes",
            before: from["excludes"],
            after: to["excludes"]
        )
        appendApplicabilityRecordChanges(
            to: &changes,
            before: applicabilityRecordsById(from["assumptions"]),
            after: applicabilityRecordsById(to["assumptions"]),
            baseRef: "modelApplicability.assumptions",
            singularKind: "assumption"
        )
        appendApplicabilityRecordChanges(
            to: &changes,
            before: applicabilityRecordsById(from["invalidationTriggers"]),
            after: applicabilityRecordsById(to["invalidationTriggers"]),
            baseRef: "modelApplicability.invalidationTriggers",
            singularKind: "invalidationTrigger"
        )

        if changes.isEmpty {
            changes.append([
                "kind": "modelApplicabilityChanged",
                "ref": "modelApplicability"
            ])
        }
        return changes
    }

    private func appendApplicabilityRecordChanges(
        to changes: inout [JSONObject],
        before: [String: JSONObject],
        after: [String: JSONObject],
        baseRef: String,
        singularKind: String
    ) {
        appendRefChanges(
            to: &changes,
            kind: "\(singularKind)Added",
            refs: sortedDifference(Set(after.keys), Set(before.keys)).map { "\(baseRef).\($0)" }
        )
        appendRefChanges(
            to: &changes,
            kind: "\(singularKind)Removed",
            refs: sortedDifference(Set(before.keys), Set(after.keys)).map { "\(baseRef).\($0)" }
        )
        for id in Set(before.keys).intersection(Set(after.keys)).sorted() {
            appendComparableChange(
                to: &changes,
                kind: "\(singularKind)Changed",
                ref: "\(baseRef).\(id)",
                before: before[id],
                after: after[id]
            )
        }
    }

    private func applicabilityRecordsById(_ value: Any?) -> [String: JSONObject] {
        (value as? [Any] ?? [])
            .compactMap { $0 as? JSONObject }
            .reduce(into: [String: JSONObject]()) { output, record in
                if let id = string(record["id"]) {
                    output[id] = record
                }
            }
    }

    private func appendComparableChange(to changes: inout [JSONObject], kind: String, ref: String, before: Any?, after: Any?) {
        guard jsonComparable(before) != jsonComparable(after) else { return }
        changes.append([
            "kind": kind,
            "ref": ref
        ])
    }

    private func appendRefChanges(to changes: inout [JSONObject], kind: String, refs: [String]) {
        for ref in refs where !ref.isEmpty {
            changes.append([
                "kind": kind,
                "ref": ref
            ])
        }
    }
}
