import Foundation
import Yams

public struct GoldenIntentValidationResult {
    public let passed: Bool
    public let report: [String: Any]
}

extension OntologyCompiler {
    public func validateGoldenIntent(
        expectationPath: OntologySourcePath,
        candidatePath: OntologySourcePath,
        outPath: OntologyOutputPath?
    ) throws -> GoldenIntentValidationResult {
        diagnostics = []
        guard let expectation = loadGoldenIntentExpectation(path: expectationPath.path),
              let candidate = load(path: candidatePath.path) else {
            throw OntologyCompilerError.packageError(diagnostics)
        }
        if hasErrors(diagnostics) {
            throw OntologyCompilerError.packageError(diagnostics)
        }
        validate(candidate)
        if hasErrors(diagnostics) {
            throw OntologyCompilerError.packageError(diagnostics)
        }

        let report = goldenIntentReport(
            expectation: expectation,
            expectationPath: expectationPath.path,
            candidate: candidate,
            candidatePath: candidatePath.path
        )
        if let outPath {
            try writeYAML(report, to: outPath.url)
        }
        let passed = ((report["result"] as? JSONObject)?["passed"] as? Bool) ?? false
        return GoldenIntentValidationResult(passed: passed, report: report)
    }

    private func loadGoldenIntentExpectation(path: String) -> JSONObject? {
        let url = URL(fileURLWithPath: path)
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            add("io.read", path, "Cannot read file: \(error.localizedDescription)")
            return nil
        }
        scanUnsafeSource(source, filePath: path)

        let parsed: Any?
        do {
            parsed = try Yams.load(yaml: source)
        } catch {
            add("yaml.parse", path, "YAML parse error: \(error)")
            return nil
        }
        guard let root = parsed as? JSONObject else {
            add("goldenIntent.type", "expectation", "Expectation root must be a mapping object")
            return nil
        }
        scanUnsafeNode(root, path: "expectation")
        validateKnownKeys(
            root,
            allowed: [
                "apiVersion", "kind", "metadata", "domainFrame", "governingConcept",
                "minimumConcepts", "minimumRelations", "policyExpectations",
                "lifecycleExpectations", "trustAndEvidenceExpectations",
                "competencyQuestions", "forbiddenCoreConcepts", "qualityTargets"
            ],
            path: "expectation"
        )
        if string(root["apiVersion"]) != "ontology-induction.specgraph.io/v1alpha1" {
            add("goldenIntent.apiVersion.invalid", "expectation.apiVersion", "apiVersion must be ontology-induction.specgraph.io/v1alpha1")
        }
        if string(root["kind"]) != "GoldenIntentSemanticExpectation" {
            add("goldenIntent.kind.invalid", "expectation.kind", "kind must be GoldenIntentSemanticExpectation")
        }
        validateGoldenIntentExpectationShape(root)
        return root
    }

    private func validateGoldenIntentExpectationShape(_ root: JSONObject) {
        validateMinimumConceptShape(root)
        validateMinimumRelationShape(root)
        validatePolicyExpectationShape(root)
        validateLifecycleExpectationShape(root)
        validateForbiddenConceptShape(root)
        validateCompetencyQuestionShape(root)
    }

    private func validateMinimumConceptShape(_ root: JSONObject) {
        if let concepts = root["minimumConcepts"] as? JSONObject {
            for category in concepts.keys.sorted() where concepts[category] as? [Any] == nil {
                add("goldenIntent.minimumConcepts.type", "expectation.minimumConcepts.\(category)", "minimumConcepts categories must be arrays")
            }
        }
    }

    private func validateMinimumRelationShape(_ root: JSONObject) {
        if root.keys.contains("minimumRelations") {
            validateArrayOfObjects(root["minimumRelations"], path: "expectation.minimumRelations")
        }
    }

    private func validatePolicyExpectationShape(_ root: JSONObject) {
        if let policyExpectations = root["policyExpectations"] as? JSONObject {
            if policyExpectations.keys.contains("mustInclude"), policyExpectations["mustInclude"] as? [Any] == nil {
                add("goldenIntent.policyExpectations.type", "expectation.policyExpectations.mustInclude", "mustInclude must be an array")
            }
            if let enforceability = policyExpectations["enforceability"] as? JSONObject {
                for level in enforceability.keys.sorted() where enforceability[level] as? [Any] == nil {
                    add("goldenIntent.policyExpectations.type", "expectation.policyExpectations.enforceability.\(level)", "enforceability groups must be arrays")
                }
            }
        }
    }

    private func validateLifecycleExpectationShape(_ root: JSONObject) {
        if let lifecycle = root["lifecycleExpectations"] as? JSONObject,
           lifecycle.keys.contains("stateMachines") {
            validateArrayOfObjects(lifecycle["stateMachines"], path: "expectation.lifecycleExpectations.stateMachines")
            for (index, machine) in ((lifecycle["stateMachines"] as? [Any]) ?? []).enumerated() {
                guard let machineObject = machine as? JSONObject,
                      machineObject.keys.contains("mustIncludeStates"),
                      machineObject["mustIncludeStates"] as? [Any] == nil else {
                    continue
                }
                add("goldenIntent.lifecycleExpectations.type", "expectation.lifecycleExpectations.stateMachines[\(index)].mustIncludeStates", "mustIncludeStates must be an array")
            }
        }
    }

    private func validateForbiddenConceptShape(_ root: JSONObject) {
        if root.keys.contains("forbiddenCoreConcepts") {
            validateArrayOfObjects(root["forbiddenCoreConcepts"], path: "expectation.forbiddenCoreConcepts")
        }
    }

    private func validateCompetencyQuestionShape(_ root: JSONObject) {
        if let competencyQuestions = root["competencyQuestions"] as? JSONObject,
           competencyQuestions.keys.contains("mustCover"),
           competencyQuestions["mustCover"] as? [Any] == nil {
            add("goldenIntent.competencyQuestions.type", "expectation.competencyQuestions.mustCover", "mustCover must be an array")
        }
    }

    private func validateArrayOfObjects(_ value: Any?, path: String) {
        guard let array = value as? [Any] else {
            add("goldenIntent.array.type", path, "\(path) must be an array")
            return
        }
        for (index, item) in array.enumerated() where item as? JSONObject == nil {
            add("goldenIntent.array.item.type", "\(path)[\(index)]", "\(path)[\(index)] must be an object")
        }
    }

    private func goldenIntentReport(
        expectation: JSONObject,
        expectationPath: String,
        candidate: LoadedPackage,
        candidatePath: String
    ) -> JSONObject {
        var checks = [JSONObject]()
        let spec = candidate.spec
        let classes = spec["classes"] as? JSONObject ?? [:]
        let relations = spec["relations"] as? JSONObject ?? [:]
        let policies = spec["policies"] as? JSONObject ?? [:]
        let stateMachines = spec["stateMachines"] as? JSONObject ?? [:]

        checks.append(contentsOf: governingConceptChecks(expectation, classes: classes))
        checks.append(contentsOf: minimumConceptChecks(expectation, classes: classes))
        checks.append(contentsOf: minimumRelationChecks(expectation, relations: relations))
        checks.append(contentsOf: policyExpectationChecks(expectation, policies: policies))
        checks.append(contentsOf: lifecycleExpectationChecks(expectation, stateMachines: stateMachines))
        checks.append(contentsOf: forbiddenConceptChecks(expectation, classes: classes))

        let failed = checks.filter { string($0["status"]) == "fail" }
        let manualReview = competencyQuestionManualReview(expectation)
        return [
            "apiVersion": "ontology-induction.specgraph.io/v1alpha1",
            "kind": "GoldenIntentValidationReport",
            "metadata": [
                "expectation": expectationPath,
                "candidate": candidatePath,
                "candidatePackage": candidate.id,
                "candidateVersion": candidate.version
            ],
            "result": [
                "passed": failed.isEmpty,
                "automatedChecks": [
                    "passed": checks.count - failed.count,
                    "failed": failed.count
                ]
            ],
            "checks": checks,
            "manualReview": manualReview
        ]
    }

    private func governingConceptChecks(_ expectation: JSONObject, classes: JSONObject) -> [JSONObject] {
        guard let governingConcept = expectation["governingConcept"] as? JSONObject,
              let id = string(governingConcept["id"]) else {
            return [check(section: "governingConcept", id: "governingConcept", status: "fail", message: "governingConcept.id is required")]
        }
        guard let candidateClass = classes[id] as? JSONObject else {
            return [check(section: "governingConcept", id: id, status: "fail", message: "governing concept is missing")]
        }
        let mustBeCentral = governingConcept["mustBeCentral"] as? Bool ?? false
        if mustBeCentral, candidateClass["central"] as? Bool != true {
            return [check(section: "governingConcept", id: id, status: "fail", message: "governing concept must be central")]
        }
        return [check(section: "governingConcept", id: id, status: "pass", message: "governing concept is present")]
    }

    private func minimumConceptChecks(_ expectation: JSONObject, classes: JSONObject) -> [JSONObject] {
        guard let groups = expectation["minimumConcepts"] as? JSONObject else { return [] }
        var checks = [JSONObject]()
        for category in groups.keys.sorted() {
            let concepts = (groups[category] as? [Any] ?? []).compactMap { string($0) }.sorted()
            for concept in concepts {
                checks.append(check(
                    section: "minimumConcepts.\(category)",
                    id: concept,
                    status: classes[concept] == nil ? "fail" : "pass",
                    message: classes[concept] == nil ? "required concept is missing" : "required concept is present"
                ))
            }
        }
        return checks
    }

    private func minimumRelationChecks(_ expectation: JSONObject, relations: JSONObject) -> [JSONObject] {
        let expectedRelations = (expectation["minimumRelations"] as? [Any] ?? []).compactMap { $0 as? JSONObject }
        return expectedRelations.sorted { string($0["id"]) ?? "" < string($1["id"]) ?? "" }.map { expected in
            let id = string(expected["id"]) ?? ""
            guard let relation = relations[id] as? JSONObject else {
                return check(section: "minimumRelations", id: id, status: "fail", message: "required relation is missing")
            }
            let domainOK = string(relation["domain"]).map(refName) == string(expected["domain"]).map(refName)
            let expectedRange = string(expected["range"]) ?? ""
            let rangeOK = relationRangeRefs(relation["range"] ?? "").map(refName).contains(refName(expectedRange))
            if domainOK, rangeOK {
                return check(section: "minimumRelations", id: id, status: "pass", message: "required relation shape is present")
            }
            return check(section: "minimumRelations", id: id, status: "fail", message: "required relation domain or range does not match")
        }
    }

    private func policyExpectationChecks(_ expectation: JSONObject, policies: JSONObject) -> [JSONObject] {
        guard let policyExpectations = expectation["policyExpectations"] as? JSONObject else { return [] }
        var checks = [JSONObject]()
        let mustInclude = (policyExpectations["mustInclude"] as? [Any] ?? []).compactMap { string($0) }.sorted()
        for policy in mustInclude {
            checks.append(check(
                section: "policyExpectations.mustInclude",
                id: policy,
                status: policies[policy] == nil ? "fail" : "pass",
                message: policies[policy] == nil ? "required policy is missing" : "required policy is present"
            ))
        }
        let enforceability = policyExpectations["enforceability"] as? JSONObject ?? [:]
        for level in enforceability.keys.sorted() {
            let expectedPolicies = (enforceability[level] as? [Any] ?? []).compactMap { string($0) }.sorted()
            for policy in expectedPolicies {
                let actual = (policies[policy] as? JSONObject).flatMap { string($0["enforceability"]) }
                checks.append(check(
                    section: "policyExpectations.enforceability.\(level)",
                    id: policy,
                    status: actual == level ? "pass" : "fail",
                    message: actual == level ? "policy enforceability matches" : "policy enforceability does not match"
                ))
            }
        }
        return checks
    }

    private func lifecycleExpectationChecks(_ expectation: JSONObject, stateMachines: JSONObject) -> [JSONObject] {
        let lifecycle = expectation["lifecycleExpectations"] as? JSONObject ?? [:]
        let expectedMachines = (lifecycle["stateMachines"] as? [Any] ?? []).compactMap { $0 as? JSONObject }
        var checks = [JSONObject]()
        for expected in expectedMachines.sorted(by: { string($0["id"]) ?? "" < string($1["id"]) ?? "" }) {
            let id = string(expected["id"]) ?? ""
            guard let machine = stateMachines[id] as? JSONObject else {
                checks.append(check(section: "lifecycleExpectations.stateMachines", id: id, status: "fail", message: "state machine is missing"))
                continue
            }
            checks.append(check(section: "lifecycleExpectations.stateMachines", id: id, status: "pass", message: "state machine is present"))
            let actualStates = Set((machine["states"] as? [Any] ?? []).compactMap { string($0) })
            let expectedStates = (expected["mustIncludeStates"] as? [Any] ?? []).compactMap { string($0) }.sorted()
            for state in expectedStates {
                checks.append(check(
                    section: "lifecycleExpectations.states",
                    id: "\(id).\(state)",
                    status: actualStates.contains(state) ? "pass" : "fail",
                    message: actualStates.contains(state) ? "required state is present" : "required state is missing"
                ))
            }
        }
        return checks
    }

    private func forbiddenConceptChecks(_ expectation: JSONObject, classes: JSONObject) -> [JSONObject] {
        let forbidden = (expectation["forbiddenCoreConcepts"] as? [Any] ?? []).compactMap { $0 as? JSONObject }
        return forbidden.sorted { string($0["id"]) ?? "" < string($1["id"]) ?? "" }.map { item in
            let id = string(item["id"]) ?? ""
            let present = classes[id] != nil
            var result = check(
                section: "forbiddenCoreConcepts",
                id: id,
                status: present ? "fail" : "pass",
                message: present ? "forbidden concept is present" : "forbidden concept is absent"
            )
            if let reason = string(item["reason"]) {
                result["reason"] = reason
            }
            return result
        }
    }

    private func competencyQuestionManualReview(_ expectation: JSONObject) -> JSONObject {
        let questions = expectation["competencyQuestions"] as? JSONObject ?? [:]
        let mustCover = (questions["mustCover"] as? [Any] ?? []).compactMap { string($0) }.sorted()
        return [
            "competencyQuestions": [
                "status": "manual_review_required",
                "mustCover": mustCover
            ]
        ]
    }

    private func check(section: String, id: String, status: String, message: String) -> JSONObject {
        [
            "section": section,
            "id": id,
            "status": status,
            "message": message
        ]
    }
}
