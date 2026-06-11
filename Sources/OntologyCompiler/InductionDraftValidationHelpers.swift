import Foundation

extension OntologyCompiler {
    func validateProvenance(_ object: JSONObject, path: String) {
        let provenance = requiredArray(object, "provenance", path: path, code: "inductionDraft.provenance.required")
        if provenance.isEmpty {
            add("inductionDraft.provenance.empty", path, "\(path) must contain at least one provenance entry")
        }
        for (index, item) in provenance.enumerated() {
            let itemPath = "\(path)[\(index)]"
            guard let itemObject = item as? JSONObject else {
                add("inductionDraft.provenance.item.type", itemPath, "\(itemPath) must be an object")
                continue
            }
            validateKnownKeys(itemObject, allowed: ["source", "note"], path: itemPath)
            _ = requiredString(
                itemObject,
                "source",
                path: "\(itemPath).source",
                code: "inductionDraft.provenance.source.required"
            )
            _ = requiredString(
                itemObject,
                "note",
                path: "\(itemPath).note",
                code: "inductionDraft.provenance.note.required"
            )
        }
    }

    func validateUncertainties(_ object: JSONObject, path: String) {
        let uncertainties = requiredArray(
            object,
            "uncertainties",
            path: path,
            code: "inductionDraft.uncertainties.required"
        )
        for (index, item) in uncertainties.enumerated() {
            let itemPath = "\(path)[\(index)]"
            guard let itemObject = item as? JSONObject else {
                add("inductionDraft.uncertainties.item.type", itemPath, "\(itemPath) must be an object")
                continue
            }
            validateKnownKeys(itemObject, allowed: ["id", "question"], path: itemPath)
            _ = requiredString(itemObject, "id", path: "\(itemPath).id", code: "inductionDraft.uncertainties.id.required")
            _ = requiredString(
                itemObject,
                "question",
                path: "\(itemPath).question",
                code: "inductionDraft.uncertainties.question.required"
            )
        }
    }

    func validateGoverningConcept(_ object: JSONObject, path: String) {
        guard let governingConcept = requiredObject(
            object,
            "governingConcept",
            path: path,
            code: "inductionDraft.governingConcept.required"
        ) else { return }
        validateKnownKeys(governingConcept, allowed: ["id", "rationale"], path: path)
        _ = requiredString(governingConcept, "id", path: "\(path).id", code: "inductionDraft.governingConcept.id.required")
        _ = requiredString(
            governingConcept,
            "rationale",
            path: "\(path).rationale",
            code: "inductionDraft.governingConcept.rationale.required"
        )
    }

    func validateIssues(_ object: JSONObject, path: String) {
        let issues = requiredArray(object, "issues", path: path, code: "inductionDraft.issues.required")
        for (index, item) in issues.enumerated() {
            let itemPath = "\(path)[\(index)]"
            guard let itemObject = item as? JSONObject else {
                add("inductionDraft.issues.item.type", itemPath, "\(itemPath) must be an object")
                continue
            }
            validateKnownKeys(itemObject, allowed: ["id", "severity", "message", "affects", "suggestedFix"], path: itemPath)
            _ = requiredString(itemObject, "id", path: "\(itemPath).id", code: "inductionDraft.issues.id.required")
            let severity = requiredString(
                itemObject,
                "severity",
                path: "\(itemPath).severity",
                code: "inductionDraft.issues.severity.required"
            )
            validateEnum(
                severity,
                allowed: ["low", "medium", "high", "blocker"],
                path: "\(itemPath).severity",
                code: "inductionDraft.issues.severity.invalid"
            )
            _ = requiredString(
                itemObject,
                "message",
                path: "\(itemPath).message",
                code: "inductionDraft.issues.message.required"
            )
        }
    }

    func validateQuestions(_ object: JSONObject, path: String) {
        let questions = requiredArray(object, "questions", path: path, code: "inductionDraft.questions.required")
        for (index, item) in questions.enumerated() {
            let itemPath = "\(path)[\(index)]"
            guard let itemObject = item as? JSONObject else {
                add("inductionDraft.questions.item.type", itemPath, "\(itemPath) must be an object")
                continue
            }
            validateKnownKeys(itemObject, allowed: ["id", "question", "blocksApproval"], path: itemPath)
            _ = requiredString(itemObject, "id", path: "\(itemPath).id", code: "inductionDraft.questions.id.required")
            _ = requiredString(
                itemObject,
                "question",
                path: "\(itemPath).question",
                code: "inductionDraft.questions.question.required"
            )
            _ = requiredBool(
                itemObject,
                "blocksApproval",
                path: "\(itemPath).blocksApproval",
                code: "inductionDraft.questions.blocksApproval.required"
            )
        }
    }

    func requiredConfidence(_ object: JSONObject, _ key: String, path: String) -> Double? {
        guard object.keys.contains(key) else {
            add("inductionDraft.confidence.required", path, "\(path) is required")
            return nil
        }
        guard let value = object[key], !(value is Bool) else {
            add("inductionDraft.confidence.type", path, "\(path) must be a number from 0.0 through 1.0")
            return nil
        }
        let number: Double?
        if let double = value as? Double {
            number = double
        } else if let int = value as? Int {
            number = Double(int)
        } else {
            number = nil
        }
        guard let number else {
            add("inductionDraft.confidence.type", path, "\(path) must be a number from 0.0 through 1.0")
            return nil
        }
        if number < 0 || number > 1 {
            add("inductionDraft.confidence.range", path, "\(path) must be between 0.0 and 1.0")
        }
        return number
    }

    func validateEnum(_ value: String?, allowed: Set<String>, path: String, code: String) {
        guard let value, !allowed.contains(value) else { return }
        add(code, path, "\(path) must be one of \(allowed.sorted().joined(separator: ", "))")
    }

    func artifactStatus(_ artifact: InductionDraftArtifactDescriptor, from start: Int) -> JSONObject {
        let failed = diagnostics.dropFirst(start).contains { $0.severity == "error" }
        return [
            "name": artifact.name,
            "path": artifact.fileName,
            "status": failed ? "fail" : "pass"
        ]
    }

    func inductionDraftReport(
        directory: String,
        passed: Bool,
        artifactReports: [JSONObject],
        diagnostics: [Diagnostic]
    ) -> JSONObject {
        [
            "apiVersion": inductionDraftApiVersion,
            "kind": "InductionDraftValidationReport",
            "metadata": [
                "draftDirectory": directory
            ],
            "result": [
                "passed": passed,
                "artifactsChecked": artifactReports.count,
                "errors": diagnostics.filter { $0.severity == "error" }.count,
                "warnings": diagnostics.filter { $0.severity == "warning" }.count
            ],
            "trustBoundary": [
                "status": "candidate_only",
                "message": "validate-draft checks structure; approval requires compiler validation and governance"
            ],
            "artifacts": artifactReports,
            "diagnostics": diagnostics.map {
                [
                    "code": $0.code,
                    "severity": $0.severity,
                    "path": $0.path,
                    "message": $0.message
                ]
            }
        ]
    }

    func sortedInductionDraftDiagnostics() -> [Diagnostic] {
        diagnostics.sorted {
            [$0.path, $0.code, $0.message].joined(separator: "\u{1f}") <
                [$1.path, $1.code, $1.message].joined(separator: "\u{1f}")
        }
    }
}
