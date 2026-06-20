import Foundation

extension OntologyCompiler {
    func validateModelApplicability(_ value: Any, path: String) {
        guard let profile = value as? JSONObject else {
            add("modelApplicability.type", path, "Model applicability profile must be an object")
            return
        }
        validateKnownKeys(profile, allowed: ["appliesTo", "excludes", "assumptions", "invalidationTriggers"], path: path)
        if let appliesTo = profile["appliesTo"] {
            validateApplicabilityScope(appliesTo, path: "\(path).appliesTo")
        }
        if let excludes = profile["excludes"] {
            validateApplicabilityScope(excludes, path: "\(path).excludes")
        }
        if let assumptions = profile["assumptions"] {
            validateApplicabilityRecords(assumptions, path: "\(path).assumptions", singularName: "assumption")
        }
        if let triggers = profile["invalidationTriggers"] {
            validateApplicabilityRecords(triggers, path: "\(path).invalidationTriggers", singularName: "invalidation trigger")
        }
    }

    func validateApplicabilityScope(_ value: Any, path: String) {
        guard let scope = value as? JSONObject else {
            add("modelApplicability.scope.type", path, "Applicability scope must be an object")
            return
        }
        validateKnownKeys(
            scope,
            allowed: ["domains", "lifecyclePhases", "agentTypes", "subsystems", "runtimes", "platforms", "contexts"],
            path: path
        )
        for key in scope.keys.sorted() {
            let fieldPath = "\(path).\(key)"
            guard let values = scope[key] as? [Any] else {
                add("modelApplicability.scope.array", fieldPath, "Applicability scope field must be an array")
                continue
            }
            if values.isEmpty {
                add("modelApplicability.scope.empty", fieldPath, "Applicability scope field must not be empty when present")
            }
            for (index, value) in values.enumerated() where !isNonEmptyString(value) {
                add("modelApplicability.scope.item.type", "\(fieldPath)[\(index)]", "Applicability scope item must be a non-empty string")
            }
        }
    }

    func validateApplicabilityRecords(_ value: Any, path: String, singularName: String) {
        guard let records = value as? [Any] else {
            add("modelApplicability.records.type", path, "Model applicability \(singularName) list must be an array")
            return
        }
        for (index, item) in records.enumerated() {
            let recordPath = "\(path)[\(index)]"
            guard let record = item as? JSONObject else {
                add("modelApplicability.record.type", recordPath, "Model applicability \(singularName) must be an object")
                continue
            }
            validateKnownKeys(record, allowed: ["id", "text", "layer"], path: recordPath)
            if let id = requiredString(record, "id", path: "\(recordPath).id", code: "modelApplicability.record.id.required") {
                validateFieldName(id, path: "\(recordPath).id", code: "modelApplicability.record.id.invalid")
            }
            _ = requiredString(record, "text", path: "\(recordPath).text", code: "modelApplicability.record.text.required")
            validateLayer(record, path: recordPath)
        }
    }

    private func isNonEmptyString(_ value: Any) -> Bool {
        guard let value = string(value) else { return false }
        return !value.isEmpty
    }
}
