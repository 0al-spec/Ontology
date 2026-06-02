import Foundation
import XCTest
@testable import OntologyCompiler

final class GovernanceDecisionValidationTests: XCTestCase {
    func testGovernanceDecisionValidationPassesValidApproval() throws {
        let report = try makeTemporaryDirectory(name: "governance-valid")
            .appendingPathComponent("report.yaml")
        let result = try OntologyCompiler().validateGovernanceDecision(
            decisionPath: OntologySourcePath(path: "SPECS/ontology/examples/governance/approved-decision.yaml"),
            packagePath: OntologySourcePath(path: "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"),
            goldenReportPath: nil,
            outPath: OntologyOutputPath(path: report.path)
        )

        XCTAssertTrue(result.passed, result.diagnostics.map(\.code).joined(separator: ", "))
        XCTAssertTrue(FileManager.default.fileExists(atPath: report.path))
        XCTAssertEqual(result.report["kind"] as? String, "OntologyGovernanceDecisionValidationReport")
    }

    func testGovernanceDecisionValidationRejectsAgentApproval() throws {
        let result = try OntologyCompiler().validateGovernanceDecision(
            decisionPath: OntologySourcePath(path: "SPECS/ontology/examples/governance/invalid-agent-approval.yaml"),
            packagePath: nil,
            goldenReportPath: nil,
            outPath: nil
        )

        XCTAssertFalse(result.passed)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "governance.decision.actor.authority.invalid" })
    }

    func testGovernanceDecisionValidationRejectsPackageMismatch() throws {
        let decision = try makeTemporaryDirectory(name: "governance-mismatch")
            .appendingPathComponent("decision.yaml")
        var text = try String(contentsOfFile: "SPECS/ontology/examples/governance/approved-decision.yaml")
        text = text.replacingOccurrences(of: "version: 0.1.0", with: "version: 9.9.9")
        try text.write(to: decision, atomically: true, encoding: .utf8)

        let result = try OntologyCompiler().validateGovernanceDecision(
            decisionPath: OntologySourcePath(path: decision.path),
            packagePath: OntologySourcePath(path: "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"),
            goldenReportPath: nil,
            outPath: nil
        )

        XCTAssertFalse(result.passed)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "governance.targetPackage.mismatch" })
    }

    func testGovernanceDecisionValidationRejectsFailingGoldenReportForApproval() throws {
        let report = try makeTemporaryDirectory(name: "governance-golden-report")
            .appendingPathComponent("golden-report.yaml")
        try """
        apiVersion: ontology-induction.specgraph.io/v1alpha1
        kind: GoldenIntentValidationReport
        result:
          passed: false
        """.write(to: report, atomically: true, encoding: .utf8)

        let result = try OntologyCompiler().validateGovernanceDecision(
            decisionPath: OntologySourcePath(path: "SPECS/ontology/examples/governance/approved-decision.yaml"),
            packagePath: nil,
            goldenReportPath: OntologySourcePath(path: report.path),
            outPath: nil
        )

        XCTAssertFalse(result.passed)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "governance.goldenReport.failed" })
    }

    private func makeTemporaryDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
