import Foundation
import Yams

public struct SpecGraphOwnerDecisionExportResult {
    public let report: [String: Any]
    public let decisionCount: Int
}

private struct SpecGraphOwnerDecisionFields {
    let decisionId: String
    let candidateId: String
    let intakeId: String
    let decisionState: String
    let decisionRef: String
    let decidedBy: String
    let decidedAt: String
    let accepted: Bool
}

extension OntologyCompiler {
    public func exportSpecGraphOwnerDecisions(
        decisionSetPath: OntologySourcePath,
        outPath: OntologyOutputPath
    ) throws -> SpecGraphOwnerDecisionExportResult {
        diagnostics = []
        guard let decisionSet = loadSpecGraphOwnerDecisionSet(path: decisionSetPath.path) else {
            throw OntologyCompilerError.packageError(sortedSpecGraphOwnerDecisionDiagnostics())
        }

        let sourceArtifacts = validateSpecGraphOwnerDecisionSourceArtifacts(decisionSet)
        let decisions = validateSpecGraphOwnerDecisions(decisionSet)

        let sorted = sortedSpecGraphOwnerDecisionDiagnostics()
        if hasErrors(sorted) {
            throw OntologyCompilerError.packageError(sorted)
        }

        let report = specGraphOwnerDecisionReport(
            decisionSetPath: decisionSetPath.path,
            outPath: outPath.path,
            sourceArtifacts: sourceArtifacts,
            decisions: decisions
        )
        let parent = outPath.url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try write(json: report, to: outPath.url)
        return SpecGraphOwnerDecisionExportResult(report: report, decisionCount: decisions.count)
    }

    private func sortedSpecGraphOwnerDecisionDiagnostics() -> [Diagnostic] {
        diagnostics.sorted {
            [$0.path, $0.code, $0.message].joined(separator: "\u{1f}") <
                [$1.path, $1.code, $1.message].joined(separator: "\u{1f}")
        }
    }

    private func loadSpecGraphOwnerDecisionSet(path: String) -> JSONObject? {
        let url = URL(fileURLWithPath: path)
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            add("specgraphOwnerDecision.io.read", path, "Cannot read file: \(error.localizedDescription)")
            return nil
        }
        scanUnsafeSource(source, filePath: path)

        let parsed: Any?
        do {
            parsed = try Yams.load(yaml: source)
        } catch {
            add("specgraphOwnerDecision.yaml.parse", path, "YAML parse error: \(error)")
            return nil
        }
        guard let root = parsed as? JSONObject else {
            add("specgraphOwnerDecision.type", "decisionSet", "Decision set root must be a mapping object")
            return nil
        }
        scanUnsafeNode(root, path: "decisionSet")
        validateKnownKeys(
            root,
            allowed: ["artifact_kind", "schema_version", "source_artifacts", "target", "decisions"],
            path: "decisionSet"
        )
        if string(root["artifact_kind"]) != "ontology_specgraph_owner_decision_set" {
            add(
                "specgraphOwnerDecision.kind.invalid",
                "decisionSet.artifact_kind",
                "artifact_kind must be ontology_specgraph_owner_decision_set"
            )
        }
        if root["schema_version"] as? Int != 1 {
            add("specgraphOwnerDecision.schemaVersion.invalid", "decisionSet.schema_version", "schema_version must be 1")
        }
        validateSpecGraphOwnerDecisionTarget(root)
        return root
    }

    private func validateSpecGraphOwnerDecisionTarget(_ root: JSONObject) {
        guard let target = requiredObject(
            root,
            "target",
            path: "decisionSet.target",
            code: "specgraphOwnerDecision.target.required"
        ) else { return }
        validateKnownKeys(target, allowed: ["target_kind", "target_ref"], path: "decisionSet.target")
        if requiredString(
            target,
            "target_kind",
            path: "decisionSet.target.target_kind",
            code: "specgraphOwnerDecision.target.kind.required"
        ) != "proposal" {
            add("specgraphOwnerDecision.target.kind.invalid", "decisionSet.target.target_kind", "target_kind must be proposal")
        }
        if requiredString(
            target,
            "target_ref",
            path: "decisionSet.target.target_ref",
            code: "specgraphOwnerDecision.target.ref.required"
        ) != "SG-RFC-0114" {
            add("specgraphOwnerDecision.target.ref.invalid", "decisionSet.target.target_ref", "target_ref must be SG-RFC-0114")
        }
    }

    private func validateSpecGraphOwnerDecisionSourceArtifacts(_ root: JSONObject) -> JSONObject {
        guard let sourceArtifacts = requiredObject(
            root,
            "source_artifacts",
            path: "decisionSet.source_artifacts",
            code: "specgraphOwnerDecision.sourceArtifacts.required"
        ) else { return [:] }
        validateKnownKeys(
            sourceArtifacts,
            allowed: ["ontology_closed_loop_evidence"],
            path: "decisionSet.source_artifacts"
        )
        _ = requiredString(
            sourceArtifacts,
            "ontology_closed_loop_evidence",
            path: "decisionSet.source_artifacts.ontology_closed_loop_evidence",
            code: "specgraphOwnerDecision.sourceArtifacts.closedLoop.required"
        )
        return sourceArtifacts
    }

    private func validateSpecGraphOwnerDecisions(_ root: JSONObject) -> [JSONObject] {
        let rawDecisions = requiredArray(
            root,
            "decisions",
            path: "decisionSet.decisions",
            code: "specgraphOwnerDecision.decisions.required"
        )
        if rawDecisions.isEmpty {
            add("specgraphOwnerDecision.decisions.empty", "decisionSet.decisions", "decisions must contain at least one entry")
        }

        var exported: [JSONObject] = []
        var seenDecisionIds = Set<String>()
        for (index, rawDecision) in rawDecisions.enumerated() {
            if let decision = validateSpecGraphOwnerDecision(
                rawDecision,
                index: index,
                seenDecisionIds: &seenDecisionIds
            ) {
                exported.append(decision)
            }
        }
        return exported.sorted {
            (string($0["decision_id"]) ?? "") < (string($1["decision_id"]) ?? "")
        }
    }

    private func validateSpecGraphOwnerDecision(
        _ rawDecision: Any,
        index: Int,
        seenDecisionIds: inout Set<String>
    ) -> JSONObject? {
        let path = "decisionSet.decisions[\(index)]"
        guard let decision = rawDecision as? JSONObject else {
            add("specgraphOwnerDecision.decision.type", path, "\(path) must be an object")
            return nil
        }
        validateSpecGraphOwnerDecisionKeys(decision, path: path)

        let decisionId = requiredString(decision, "decision_id", path: "\(path).decision_id", code: "specgraphOwnerDecision.decision.id.required")
        if let decisionId, !seenDecisionIds.insert(decisionId).inserted {
            add("specgraphOwnerDecision.decision.id.duplicate", "\(path).decision_id", "decision_id must be unique")
        }
        let candidateId = requiredString(decision, "candidate_id", path: "\(path).candidate_id", code: "specgraphOwnerDecision.decision.candidate.required")
        let intakeId = requiredString(decision, "intake_id", path: "\(path).intake_id", code: "specgraphOwnerDecision.decision.intake.required")
        let decisionState = requiredString(decision, "decision_state", path: "\(path).decision_state", code: "specgraphOwnerDecision.decision.state.required")
        validateSpecGraphOwnerDecisionState(decisionState, path: path)
        let decisionRef = requiredString(decision, "ontology_decision_ref", path: "\(path).ontology_decision_ref", code: "specgraphOwnerDecision.decision.ref.required")
        let decidedBy = requiredString(decision, "decided_by", path: "\(path).decided_by", code: "specgraphOwnerDecision.decision.actor.required")
        let decidedAt = requiredString(decision, "decided_at", path: "\(path).decided_at", code: "specgraphOwnerDecision.decision.time.required")
        let accepted = requiredBool(decision, "accepted_ontology_delta", path: "\(path).accepted_ontology_delta", code: "specgraphOwnerDecision.decision.acceptedDelta.required")
        validateSpecGraphOwnerDecisionAcceptedFlag(accepted, decisionState: decisionState, path: path)
        validateFalseBoundaryFlag(decision, field: "imports_into_specgraph", path: path)
        validateFalseBoundaryFlag(decision, field: "closes_semantic_gate", path: path)
        validateFalseBoundaryFlag(decision, field: "mutates_canonical_specs", path: path)

        guard let decisionId,
              let candidateId,
              let intakeId,
              let decisionState,
              let decisionRef,
              let decidedBy,
              let decidedAt,
              let accepted,
              specGraphOwnerDecisionStates.contains(decisionState),
              accepted == (decisionState == "accepted")
        else { return nil }

        let fields = SpecGraphOwnerDecisionFields(
            decisionId: decisionId,
            candidateId: candidateId,
            intakeId: intakeId,
            decisionState: decisionState,
            decisionRef: decisionRef,
            decidedBy: decidedBy,
            decidedAt: decidedAt,
            accepted: accepted
        )
        return specGraphOwnerDecisionOutput(source: decision, fields: fields)
    }

    private var specGraphOwnerDecisionStates: Set<String> {
        ["accepted", "rejected", "needs_clarification"]
    }

    private func validateSpecGraphOwnerDecisionKeys(_ decision: JSONObject, path: String) {
        validateKnownKeys(
            decision,
            allowed: [
                "decision_id", "candidate_id", "intake_id", "decision_state",
                "ontology_decision_ref", "decided_by", "decided_at", "reason",
                "accepted_ontology_delta", "imports_into_specgraph",
                "closes_semantic_gate", "mutates_canonical_specs"
            ],
            path: path
        )
    }

    private func validateSpecGraphOwnerDecisionState(_ decisionState: String?, path: String) {
        if let decisionState, !specGraphOwnerDecisionStates.contains(decisionState) {
            add(
                "specgraphOwnerDecision.decision.state.invalid",
                "\(path).decision_state",
                "decision_state must be accepted, rejected, or needs_clarification"
            )
        }
    }

    private func validateSpecGraphOwnerDecisionAcceptedFlag(
        _ accepted: Bool?,
        decisionState: String?,
        path: String
    ) {
        if let accepted, let decisionState, accepted != (decisionState == "accepted") {
            add(
                "specgraphOwnerDecision.decision.acceptedDelta.inconsistent",
                "\(path).accepted_ontology_delta",
                "accepted_ontology_delta must be true only for accepted decisions"
            )
        }
    }

    private func specGraphOwnerDecisionOutput(
        source: JSONObject,
        fields: SpecGraphOwnerDecisionFields
    ) -> JSONObject {
        var output: JSONObject = [
            "decision_id": fields.decisionId,
            "candidate_id": fields.candidateId,
            "intake_id": fields.intakeId,
            "decision_state": fields.decisionState,
            "ontology_decision_ref": fields.decisionRef,
            "decided_by": fields.decidedBy,
            "decided_at": fields.decidedAt,
            "accepted_ontology_delta": fields.accepted,
            "imports_into_specgraph": false,
            "closes_semantic_gate": false,
            "mutates_canonical_specs": false
        ]
        if let reason = string(source["reason"]), !reason.isEmpty {
            output["reason"] = reason
        }
        return output
    }

    private func validateFalseBoundaryFlag(_ decision: JSONObject, field: String, path: String) {
        guard decision.keys.contains(field) else { return }
        if requiredBool(
            decision,
            field,
            path: "\(path).\(field)",
            code: "specgraphOwnerDecision.decision.boundaryFlag.required"
        ) != false {
            add("specgraphOwnerDecision.decision.boundaryFlag.invalid", "\(path).\(field)", "\(field) must be false")
        }
    }

    private func specGraphOwnerDecisionReport(
        decisionSetPath: String,
        outPath: String,
        sourceArtifacts: JSONObject,
        decisions: [JSONObject]
    ) -> JSONObject {
        let acceptedCount = decisions.filter { string($0["decision_state"]) == "accepted" }.count
        let rejectedCount = decisions.filter { string($0["decision_state"]) == "rejected" }.count
        let clarificationCount = decisions.filter { string($0["decision_state"]) == "needs_clarification" }.count
        return [
            "artifact_kind": "ontology_owner_decision_report",
            "schema_version": 1,
            "proposal_id": "0114",
            "source_decision_set": decisionSetPath,
            "source_artifacts": sourceArtifacts,
            "target": [
                "target_kind": "proposal",
                "target_ref": "SG-RFC-0114"
            ],
            "canonical_mutations_allowed": false,
            "tracked_artifacts_written": false,
            "decision_states": ["accepted", "rejected", "needs_clarification"],
            "decisions": decisions,
            "ignored_decisions": [],
            "consumer_boundary": [
                "for_specgraph_decision_import_preview": true,
                "for_specspace_review_dashboard": true,
                "may_execute_prompt_agent": false,
                "may_write_ontology_package": false,
                "may_update_ontology_lockfile": false,
                "may_mutate_canonical_specs": false,
                "may_mark_candidate_accepted": false,
                "may_import_into_specgraph": false,
                "may_close_semantic_gate": false
            ],
            "authority_boundary": [
                "ontology_owner_decision_report_is_authority": false,
                "prompt_agent_execution_allowed": false,
                "automatic_import_lock_update": false,
                "automatic_canonical_node_update": false,
                "canonical_mutations_allowed": false
            ],
            "summary": [
                "status": decisions.isEmpty ? "no_decisions" : "decisions_available",
                "decision_count": decisions.count,
                "accepted_count": acceptedCount,
                "rejected_count": rejectedCount,
                "needs_clarification_count": clarificationCount,
                "ignored_decision_count": 0,
                "next_gap": "review_specgraph_decision_import_preview"
            ],
            "output_artifact": outPath
        ]
    }
}
