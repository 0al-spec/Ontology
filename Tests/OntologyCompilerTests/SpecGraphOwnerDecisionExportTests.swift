import Foundation
import OntologyCompiler
import XCTest

final class SpecGraphOwnerDecisionExportTests: XCTestCase {
    func testExportSpecGraphOwnerDecisionReportWritesSpecGraphShape() throws {
        let output = try makeTemporaryDirectory(name: "specgraph-owner-decisions")
        let reportURL = output.appendingPathComponent("ontology-owner-decision-report.json")
        let compiler = OntologyCompiler()

        let result = try compiler.exportSpecGraphOwnerDecisions(
            decisionSetPath: OntologySourcePath(
                path: "SPECS/ontology/examples/specgraph-owner-decisions/examcalc-owner-decisions.yaml"
            ),
            outPath: OntologyOutputPath(path: reportURL.path)
        )

        XCTAssertEqual(result.decisionCount, 3)
        XCTAssertTrue(FileManager.default.fileExists(atPath: reportURL.path))
        let report = try loadJSON(reportURL)
        XCTAssertEqual(report["artifact_kind"] as? String, "ontology_owner_decision_report")
        XCTAssertEqual(report["schema_version"] as? Int, 1)
        XCTAssertEqual(report["proposal_id"] as? String, "0114")
        XCTAssertEqual(report["canonical_mutations_allowed"] as? Bool, false)
        XCTAssertEqual(report["tracked_artifacts_written"] as? Bool, false)

        let sourceArtifacts = try XCTUnwrap(report["source_artifacts"] as? [String: Any])
        XCTAssertEqual(
            sourceArtifacts["ontology_closed_loop_evidence"] as? String,
            "runs/ontology_closed_loop_evidence.json"
        )

        let summary = try XCTUnwrap(report["summary"] as? [String: Any])
        XCTAssertEqual(summary["status"] as? String, "decisions_available")
        XCTAssertEqual(summary["decision_count"] as? Int, 3)
        XCTAssertEqual(summary["accepted_count"] as? Int, 1)
        XCTAssertEqual(summary["rejected_count"] as? Int, 1)
        XCTAssertEqual(summary["needs_clarification_count"] as? Int, 1)
        XCTAssertEqual(summary["ignored_decision_count"] as? Int, 0)

        let decisions = try XCTUnwrap(report["decisions"] as? [[String: Any]])
        XCTAssertEqual(decisions.count, 3)
        let byState = Dictionary(uniqueKeysWithValues: decisions.compactMap { decision -> (String, [String: Any])? in
            guard let state = decision["decision_state"] as? String else { return nil }
            return (state, decision)
        })

        let accepted = try XCTUnwrap(byState["accepted"])
        XCTAssertEqual(accepted["candidate_id"] as? String, "ontology-delta-candidate-examcalc-casfunction")
        XCTAssertEqual(accepted["accepted_ontology_delta"] as? Bool, true)
        XCTAssertEqual(accepted["imports_into_specgraph"] as? Bool, false)
        XCTAssertEqual(accepted["closes_semantic_gate"] as? Bool, false)
        XCTAssertEqual(accepted["mutates_canonical_specs"] as? Bool, false)

        let rejected = try XCTUnwrap(byState["rejected"])
        XCTAssertEqual(rejected["accepted_ontology_delta"] as? Bool, false)

        let clarification = try XCTUnwrap(byState["needs_clarification"])
        XCTAssertEqual(clarification["accepted_ontology_delta"] as? Bool, false)

        let consumerBoundary = try XCTUnwrap(report["consumer_boundary"] as? [String: Any])
        XCTAssertEqual(consumerBoundary["for_specgraph_decision_import_preview"] as? Bool, true)
        XCTAssertEqual(consumerBoundary["may_write_ontology_package"] as? Bool, false)
        XCTAssertEqual(consumerBoundary["may_update_ontology_lockfile"] as? Bool, false)
        XCTAssertEqual(consumerBoundary["may_mutate_canonical_specs"] as? Bool, false)
        XCTAssertEqual(consumerBoundary["may_import_into_specgraph"] as? Bool, false)
        XCTAssertEqual(consumerBoundary["may_close_semantic_gate"] as? Bool, false)
        try assertAuthorityBoundary(report)
    }

    func testExportRejectsAcceptedFlagMismatchWithoutWritingReport() throws {
        let output = try makeTemporaryDirectory(name: "specgraph-owner-decisions-invalid")
        let inputURL = output.appendingPathComponent("invalid-owner-decisions.yaml")
        let reportURL = output.appendingPathComponent("report.json")
        try writeDecisionSet(inputURL, decisionState: "accepted", accepted: false)

        try assertExportFails(
            inputURL: inputURL,
            reportURL: reportURL,
            code: "specgraphOwnerDecision.decision.acceptedDelta.inconsistent"
        )
    }

    func testExportRejectsInvalidDecisionStateWithoutWritingReport() throws {
        let output = try makeTemporaryDirectory(name: "specgraph-owner-decisions-invalid-state")
        let inputURL = output.appendingPathComponent("invalid-state-owner-decisions.yaml")
        let reportURL = output.appendingPathComponent("report.json")
        try writeDecisionSet(inputURL, decisionState: "approved", accepted: false)

        try assertExportFails(
            inputURL: inputURL,
            reportURL: reportURL,
            code: "specgraphOwnerDecision.decision.state.invalid"
        )
    }

    func testExportSpecGraphOwnerDecisionsCliWritesReport() throws {
        let output = try makeTemporaryDirectory(name: "specgraph-owner-decisions-cli")
        let reportURL = output.appendingPathComponent("owner-decisions.json")

        let result = try ontologyc([
            "export-specgraph-owner-decisions",
            "SPECS/ontology/examples/specgraph-owner-decisions/examcalc-owner-decisions.yaml",
            "--out",
            reportURL.path
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertTrue(
            result.stdout.contains("ontologyc export-specgraph-owner-decisions: PASS"),
            result.stdout
        )
        XCTAssertTrue(result.stdout.contains("decisions=3"), result.stdout)
        let report = try loadJSON(reportURL)
        XCTAssertEqual(report["artifact_kind"] as? String, "ontology_owner_decision_report")
    }

    private func writeDecisionSet(_ inputURL: URL, decisionState: String, accepted: Bool) throws {
        try """
        artifact_kind: ontology_specgraph_owner_decision_set
        schema_version: 1
        source_artifacts:
          ontology_closed_loop_evidence: runs/ontology_closed_loop_evidence.json
        target:
          target_kind: proposal
          target_ref: SG-RFC-0114
        decisions:
          - decision_id: ontology-owner-decision-bad
            candidate_id: ontology-delta-candidate-examcalc-bad
            intake_id: ontology-delta-draft-intake-ontology-delta-candidate-examcalc-bad
            decision_state: \(decisionState)
            ontology_decision_ref: ontology-decision://edu.university.examcalc/0.1.0/bad/accepted
            decided_by: ontology-owner
            decided_at: "2026-06-14T00:00:00Z"
            accepted_ontology_delta: \(accepted)
        """.write(to: inputURL, atomically: true, encoding: .utf8)
    }

    private func assertExportFails(inputURL: URL, reportURL: URL, code: String) throws {
        let compiler = OntologyCompiler()
        do {
            _ = try compiler.exportSpecGraphOwnerDecisions(
                decisionSetPath: OntologySourcePath(path: inputURL.path),
                outPath: OntologyOutputPath(path: reportURL.path)
            )
            XCTFail("Expected owner decision export to fail")
        } catch let OntologyCompilerError.packageError(diagnostics) {
            XCTAssertTrue(
                diagnostics.contains {
                    $0.code == code
                }
            )
            XCTAssertFalse(FileManager.default.fileExists(atPath: reportURL.path))
        }
    }

    private func assertAuthorityBoundary(_ report: [String: Any]) throws {
        let boundary = try XCTUnwrap(report["authority_boundary"] as? [String: Any])
        XCTAssertEqual(boundary["ontology_owner_decision_report_is_authority"] as? Bool, false)
        XCTAssertEqual(boundary["prompt_agent_execution_allowed"] as? Bool, false)
        XCTAssertEqual(boundary["automatic_import_lock_update"] as? Bool, false)
        XCTAssertEqual(boundary["automatic_canonical_node_update"] as? Bool, false)
        XCTAssertEqual(boundary["canonical_mutations_allowed"] as? Bool, false)
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func ontologyc(_ arguments: [String]) throws -> CommandResult {
        let binary = repoRoot.appendingPathComponent(".build/debug/ontologyc")
        if !FileManager.default.fileExists(atPath: binary.path) {
            let build = try run("/usr/bin/env", ["swift", "build", "--product", "ontologyc"])
            XCTAssertEqual(build.status, 0, build.combinedOutput)
        }
        return try run(binary.path, arguments)
    }

    private func run(_ executable: String, _ arguments: [String]) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = repoRoot

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        return CommandResult(
            status: process.terminationStatus,
            stdout: String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            stderr: String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        )
    }

    private func makeTemporaryDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func loadJSON(_ url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

private struct CommandResult {
    let status: Int32
    let stdout: String
    let stderr: String

    var combinedOutput: String {
        stdout + stderr
    }
}
