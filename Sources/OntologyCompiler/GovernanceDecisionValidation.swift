import Foundation
import Yams

public struct GovernanceDecisionValidationResult {
    public let passed: Bool
    public let report: [String: Any]
    public let diagnostics: [Diagnostic]
}

extension OntologyCompiler {
    public func validateGovernanceDecision(
        decisionPath: OntologySourcePath,
        packagePath: OntologySourcePath?,
        goldenReportPath: OntologySourcePath?,
        outPath: OntologyOutputPath?
    ) throws -> GovernanceDecisionValidationResult {
        diagnostics = []
        guard let decision = loadGovernanceDecision(path: decisionPath.path) else {
            let sorted = sortedDiagnostics()
            let report = governanceDecisionReport(decisionPath: decisionPath.path, passed: false, checks: checks(from: sorted))
            if let outPath { try writeYAML(report, to: outPath.url) }
            return GovernanceDecisionValidationResult(passed: false, report: report, diagnostics: sorted)
        }

        validateGovernanceDecisionShape(decision)
        if let packagePath {
            validateGovernanceDecisionPackage(decision, packagePath: packagePath.path)
        }
        if let goldenReportPath {
            validateGovernanceDecisionGoldenReport(decision, goldenReportPath: goldenReportPath.path)
        }

        let sorted = sortedDiagnostics()
        let checks = governanceDecisionChecks(decision, diagnostics: sorted)
        let passed = sorted.allSatisfy { $0.severity != "error" }
        let report = governanceDecisionReport(decisionPath: decisionPath.path, passed: passed, checks: checks)
        if let outPath {
            try writeYAML(report, to: outPath.url)
        }
        return GovernanceDecisionValidationResult(passed: passed, report: report, diagnostics: sorted)
    }

    private func loadGovernanceDecision(path: String) -> JSONObject? {
        let url = URL(fileURLWithPath: path)
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            add("governance.io.read", path, "Cannot read file: \(error.localizedDescription)")
            return nil
        }
        scanUnsafeSource(source, filePath: path)

        let parsed: Any?
        do {
            parsed = try Yams.load(yaml: source)
        } catch {
            add("governance.yaml.parse", path, "YAML parse error: \(error)")
            return nil
        }
        guard let root = parsed as? JSONObject else {
            add("governance.type", "decision", "Decision root must be a mapping object")
            return nil
        }
        scanUnsafeNode(root, path: "decision")
        return root
    }

    private func validateGovernanceDecisionShape(_ root: JSONObject) {
        validateKnownKeys(root, allowed: ["apiVersion", "kind", "metadata", "spec"], path: "decision")
        if string(root["apiVersion"]) != "ontology-governance.specgraph.io/v1alpha1" {
            add("governance.apiVersion.invalid", "decision.apiVersion", "apiVersion must be ontology-governance.specgraph.io/v1alpha1")
        }
        if string(root["kind"]) != "OntologyGovernanceDecision" {
            add("governance.kind.invalid", "decision.kind", "kind must be OntologyGovernanceDecision")
        }
        guard let metadata = requiredObject(root, "metadata", path: "decision.metadata", code: "governance.metadata.required"),
              let spec = requiredObject(root, "spec", path: "decision.spec", code: "governance.spec.required") else {
            return
        }
        validateKnownKeys(metadata, allowed: ["id", "createdAt", "updatedAt", "source", "reviewUrl"], path: "decision.metadata")
        _ = requiredString(metadata, "id", path: "decision.metadata.id", code: "governance.metadata.id.required")
        _ = requiredString(metadata, "createdAt", path: "decision.metadata.createdAt", code: "governance.metadata.createdAt.required")

        validateKnownKeys(spec, allowed: ["targetPackage", "priorVersion", "decision", "evidence"], path: "decision.spec")
        validateGovernanceTargetPackage(spec)
        validateGovernanceDecisionBlock(spec)
        validateGovernanceEvidence(spec)
    }

    private func validateGovernanceTargetPackage(_ spec: JSONObject) {
        guard let target = requiredObject(
            spec,
            "targetPackage",
            path: "decision.spec.targetPackage",
            code: "governance.targetPackage.required"
        ) else { return }
        validateKnownKeys(target, allowed: ["id", "namespace", "version", "source", "digest"], path: "decision.spec.targetPackage")
        if let id = requiredString(target, "id", path: "decision.spec.targetPackage.id", code: "governance.targetPackage.id.required") {
            validate(id, path: "decision.spec.targetPackage.id", code: "governance.targetPackage.id.invalid") {
                matches($0, "^[a-z][a-z0-9]*(\\.[a-z0-9][a-z0-9-]*)+$")
            }
        }
        if let namespace = requiredString(
            target,
            "namespace",
            path: "decision.spec.targetPackage.namespace",
            code: "governance.targetPackage.namespace.required"
        ) {
            validate(namespace, path: "decision.spec.targetPackage.namespace", code: "governance.targetPackage.namespace.invalid") {
                matches($0, "^[a-z][a-z0-9-]*$")
            }
        }
        if let version = requiredString(
            target,
            "version",
            path: "decision.spec.targetPackage.version",
            code: "governance.targetPackage.version.required"
        ) {
            validate(version, path: "decision.spec.targetPackage.version", code: "governance.targetPackage.version.invalid") {
                matches($0, "^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)([-+][0-9A-Za-z.-]+)?$")
            }
        }
    }

    private func validateGovernanceDecisionBlock(_ spec: JSONObject) {
        guard let decision = requiredObject(
            spec,
            "decision",
            path: "decision.spec.decision",
            code: "governance.decision.required"
        ) else { return }
        validateKnownKeys(
            decision,
            allowed: ["state", "actor", "decidedAt", "rationale", "versionChange", "residualRisks", "supersedes", "followUp"],
            path: "decision.spec.decision"
        )
        let state = requiredString(decision, "state", path: "decision.spec.decision.state", code: "governance.decision.state.required")
        let allowedStates = Set(["candidate", "under_review", "changes_requested", "rejected", "approved", "merged", "superseded", "withdrawn"])
        if let state, !allowedStates.contains(state) {
            add("governance.decision.state.invalid", "decision.spec.decision.state", "state must be one of \(allowedStates.sorted().joined(separator: ", "))")
        }
        _ = requiredString(decision, "decidedAt", path: "decision.spec.decision.decidedAt", code: "governance.decision.decidedAt.required")
        let rationale = requiredArray(decision, "rationale", path: "decision.spec.decision.rationale", code: "governance.decision.rationale.required")
        if rationale.isEmpty {
            add("governance.decision.rationale.empty", "decision.spec.decision.rationale", "rationale must contain at least one entry")
        }
        for (index, item) in rationale.enumerated() where string(item)?.isEmpty != false {
            add("governance.decision.rationale.item.invalid", "decision.spec.decision.rationale[\(index)]", "rationale entries must be non-empty strings")
        }
        validateGovernanceActor(decision, state: state)
    }

    private func validateGovernanceActor(_ decision: JSONObject, state: String?) {
        guard let actor = requiredObject(
            decision,
            "actor",
            path: "decision.spec.decision.actor",
            code: "governance.decision.actor.required"
        ) else { return }
        validateKnownKeys(actor, allowed: ["id", "kind", "role", "displayName"], path: "decision.spec.decision.actor")
        _ = requiredString(actor, "id", path: "decision.spec.decision.actor.id", code: "governance.decision.actor.id.required")
        let kind = requiredString(actor, "kind", path: "decision.spec.decision.actor.kind", code: "governance.decision.actor.kind.required")
        let role = requiredString(actor, "role", path: "decision.spec.decision.actor.role", code: "governance.decision.actor.role.required")
        if let kind, !["human", "agent"].contains(kind) {
            add("governance.decision.actor.kind.invalid", "decision.spec.decision.actor.kind", "actor.kind must be human or agent")
        }
        if let role, !["authoring_agent", "proposer", "reviewer", "maintainer"].contains(role) {
            add("governance.decision.actor.role.invalid", "decision.spec.decision.actor.role", "actor.role has invalid value")
        }
        switch state {
        case "approved", "rejected":
            if kind != "human" || role != "reviewer" {
                add("governance.decision.actor.authority.invalid", "decision.spec.decision.actor", "approved and rejected decisions require kind human and role reviewer")
            }
        case "merged", "superseded":
            if kind != "human" || role != "maintainer" {
                add("governance.decision.actor.authority.invalid", "decision.spec.decision.actor", "merged and superseded decisions require kind human and role maintainer")
            }
            if state == "superseded", decision["supersedes"] as? JSONObject == nil {
                add("governance.decision.supersedes.required", "decision.spec.decision.supersedes", "superseded decisions require supersedes")
            }
        default:
            break
        }
    }

    private func validateGovernanceEvidence(_ spec: JSONObject) {
        guard let evidence = requiredObject(
            spec,
            "evidence",
            path: "decision.spec.evidence",
            code: "governance.evidence.required"
        ) else { return }
        let allowed = [
            "sourceIntent", "candidateArtifacts", "candidatePackage", "critiqueReport",
            "competencyQuestions", "compilerValidation", "repeatabilityReport",
            "compatibilityReport", "reviewRecord"
        ]
        validateKnownKeys(evidence, allowed: allowed, path: "decision.spec.evidence")
        for key in ["sourceIntent", "candidatePackage", "critiqueReport", "competencyQuestions", "compilerValidation"] {
            validateEvidenceRef(evidence[key], path: "decision.spec.evidence.\(key)", code: "governance.evidence.\(key).required")
        }
        let artifacts = requiredArray(
            evidence,
            "candidateArtifacts",
            path: "decision.spec.evidence.candidateArtifacts",
            code: "governance.evidence.candidateArtifacts.required"
        )
        if artifacts.isEmpty {
            add("governance.evidence.candidateArtifacts.empty", "decision.spec.evidence.candidateArtifacts", "candidateArtifacts must contain at least one entry")
        }
        for (index, artifact) in artifacts.enumerated() {
            validateEvidenceRef(artifact, path: "decision.spec.evidence.candidateArtifacts[\(index)]", code: "governance.evidence.candidateArtifacts.item.required")
        }
    }

    private func validateEvidenceRef(_ value: Any?, path: String, code: String) {
        guard let ref = value as? JSONObject else {
            add(code, path, "\(path) must be an object")
            return
        }
        validateKnownKeys(ref, allowed: ["uri", "digest", "result", "notes"], path: path)
        _ = requiredString(ref, "uri", path: "\(path).uri", code: "\(code).uri")
    }

    private func validateGovernanceDecisionPackage(_ decision: JSONObject, packagePath: String) {
        guard let package = load(path: packagePath) else { return }
        if hasErrors(diagnostics) { return }
        validate(package)
        if hasErrors(diagnostics) { return }
        let target = ((decision["spec"] as? JSONObject)?["targetPackage"] as? JSONObject) ?? [:]
        compareTarget(string(target["id"]), expected: package.id, path: "decision.spec.targetPackage.id")
        compareTarget(string(target["namespace"]), expected: package.namespace, path: "decision.spec.targetPackage.namespace")
        compareTarget(string(target["version"]), expected: package.version, path: "decision.spec.targetPackage.version")
    }

    private func compareTarget(_ actual: String?, expected: String, path: String) {
        guard let actual, !actual.isEmpty, actual != expected else { return }
        add("governance.targetPackage.mismatch", path, "\(path) must match supplied package value \(expected)")
    }

    private func validateGovernanceDecisionGoldenReport(_ decision: JSONObject, goldenReportPath: String) {
        guard decisionState(decision) == "approved" else { return }
        let report: JSONObject
        do {
            report = try loadYAMLObject(path: goldenReportPath, rootName: "goldenReport")
        } catch let compilerError as OntologyCompilerError {
            if case .packageError = compilerError { return }
            add("governance.goldenReport.read", goldenReportPath, "\(compilerError)")
            return
        } catch {
            add("governance.goldenReport.read", goldenReportPath, "\(error)")
            return
        }
        if string(report["kind"]) != "GoldenIntentValidationReport" {
            add("governance.goldenReport.kind.invalid", "goldenReport.kind", "golden report kind must be GoldenIntentValidationReport")
        }
        let passed = ((report["result"] as? JSONObject)?["passed"] as? Bool) ?? false
        if !passed {
            add("governance.goldenReport.failed", "goldenReport.result.passed", "approved decisions require a passing golden intent report when supplied")
        }
    }

    private func loadYAMLObject(path: String, rootName: String) throws -> JSONObject {
        let url = URL(fileURLWithPath: path)
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            add("io.read", path, "Cannot read file: \(error.localizedDescription)")
            throw OntologyCompilerError.packageError(diagnostics)
        }
        scanUnsafeSource(source, filePath: path)
        do {
            let parsed = try Yams.load(yaml: source)
            guard let object = parsed as? JSONObject else {
                add("yaml.type", rootName, "\(rootName) root must be a mapping object")
                throw OntologyCompilerError.packageError(diagnostics)
            }
            scanUnsafeNode(object, path: rootName)
            return object
        } catch let compilerError as OntologyCompilerError {
            throw compilerError
        } catch {
            add("yaml.parse", path, "YAML parse error: \(error)")
            throw OntologyCompilerError.packageError(diagnostics)
        }
    }

    private func decisionState(_ decision: JSONObject) -> String? {
        let spec = decision["spec"] as? JSONObject
        let decisionBlock = spec?["decision"] as? JSONObject
        return string(decisionBlock?["state"])
    }

    private func governanceDecisionChecks(_ decision: JSONObject, diagnostics: [Diagnostic]) -> [JSONObject] {
        let failedCodes = Set(diagnostics.map(\.code))
        return [
            check(id: "governance.apiVersion.valid", failedCodes: failedCodes, relatedCodes: ["governance.apiVersion.invalid"]),
            check(id: "governance.kind.valid", failedCodes: failedCodes, relatedCodes: ["governance.kind.invalid"]),
            check(id: "governance.actor.authority.valid", failedCodes: failedCodes, relatedCodes: ["governance.decision.actor.authority.invalid"]),
            check(id: "governance.evidence.required.present", failedCodes: failedCodes, relatedPrefixes: ["governance.evidence."]),
            check(id: "governance.targetPackage.matches", failedCodes: failedCodes, relatedCodes: ["governance.targetPackage.mismatch"]),
            check(id: "governance.goldenReport.passing", failedCodes: failedCodes, relatedPrefixes: ["governance.goldenReport."])
        ].map { $0.merging(["decisionState": decisionState(decision) ?? ""], uniquingKeysWith: { current, _ in current }) }
    }

    private func check(
        id: String,
        failedCodes: Set<String>,
        relatedCodes: Set<String> = [],
        relatedPrefixes: [String] = []
    ) -> JSONObject {
        let failed = failedCodes.contains { code in
            relatedCodes.contains(code) || relatedPrefixes.contains { code.hasPrefix($0) }
        }
        return [
            "id": id,
            "status": failed ? "fail" : "pass",
            "message": failed ? "check failed" : "check passed"
        ]
    }

    private func checks(from diagnostics: [Diagnostic]) -> [JSONObject] {
        diagnostics.map {
            [
                "id": $0.code,
                "status": "fail",
                "message": $0.message
            ]
        }
    }

    private func governanceDecisionReport(decisionPath: String, passed: Bool, checks: [JSONObject]) -> JSONObject {
        [
            "apiVersion": "ontology-governance.specgraph.io/v1alpha1",
            "kind": "OntologyGovernanceDecisionValidationReport",
            "metadata": [
                "decision": decisionPath
            ],
            "result": [
                "passed": passed,
                "checks": [
                    "passed": checks.filter { string($0["status"]) == "pass" }.count,
                    "failed": checks.filter { string($0["status"]) == "fail" }.count
                ]
            ],
            "checks": checks
        ]
    }

    private func sortedDiagnostics() -> [Diagnostic] {
        diagnostics.sorted {
            [$0.path, $0.code, $0.message].joined(separator: "\u{1f}") <
                [$1.path, $1.code, $1.message].joined(separator: "\u{1f}")
        }
    }
}
