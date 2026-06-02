import Foundation
import XCTest
@testable import OntologyCompiler

final class RegistryPublishGovernanceGateTests: XCTestCase {
    func testTrustedPublishRequiresGovernanceDecisionBeforeRegistryPut() throws {
        let compiler = OntologyCompiler()
        var putCalled = false

        XCTAssertThrowsError(
            try compiler.publishPackage(
                request: request(governanceDecisionPath: nil),
                put: { _, _, _ in putCalled = true }
            )
        ) { error in
            guard case OntologyCompilerError.packageError(let diagnostics) = error else {
                return XCTFail("Expected governance package diagnostics, got \(error)")
            }
            XCTAssertTrue(diagnostics.contains { $0.code == "registry.publish.governanceDecision.required" })
        }
        XCTAssertFalse(putCalled)
    }

    func testTrustedPublishRejectsNonApprovedDecisionBeforeRegistryPut() throws {
        let compiler = OntologyCompiler()
        let decision = try makeTemporaryDirectory(name: "publish-governance-candidate")
            .appendingPathComponent("decision.yaml")
        var text = try String(contentsOfFile: "SPECS/ontology/examples/governance/approved-decision.yaml")
        text = text.replacingOccurrences(of: "state: approved", with: "state: candidate")
        try text.write(to: decision, atomically: true, encoding: .utf8)
        var putCalled = false

        XCTAssertThrowsError(
            try compiler.publishPackage(
                request: request(governanceDecisionPath: OntologySourcePath(url: decision)),
                put: { _, _, _ in putCalled = true }
            )
        ) { error in
            guard case OntologyCompilerError.packageError(let diagnostics) = error else {
                return XCTFail("Expected governance package diagnostics, got \(error)")
            }
            XCTAssertTrue(diagnostics.contains { $0.code == "registry.publish.governanceDecision.approved.required" })
        }
        XCTAssertFalse(putCalled)
    }

    func testTrustedPublishRejectsFailingGoldenReportBeforeRegistryPut() throws {
        let compiler = OntologyCompiler()
        let goldenReport = try makeTemporaryDirectory(name: "publish-governance-golden")
            .appendingPathComponent("golden-report.yaml")
        try """
        apiVersion: ontology-induction.specgraph.io/v1alpha1
        kind: GoldenIntentValidationReport
        result:
          passed: false
        """.write(to: goldenReport, atomically: true, encoding: .utf8)
        var putCalled = false

        XCTAssertThrowsError(
            try compiler.publishPackage(
                request: request(goldenReportPath: OntologySourcePath(url: goldenReport)),
                put: { _, _, _ in putCalled = true }
            )
        ) { error in
            guard case OntologyCompilerError.packageError(let diagnostics) = error else {
                return XCTFail("Expected governance package diagnostics, got \(error)")
            }
            XCTAssertTrue(diagnostics.contains { $0.code == "governance.goldenReport.failed" })
        }
        XCTAssertFalse(putCalled)
    }

    func testTrustedPublishAcceptsApprovedDecisionWithInjectedRegistryPut() throws {
        let compiler = OntologyCompiler()
        var capturedURL: URL?
        var capturedBody: Data?

        let result = try compiler.publishPackage(
            request: request(),
            put: { url, body, _ in
                capturedURL = url
                capturedBody = body
            }
        )

        XCTAssertEqual(result.packageRef.rawValue, "edu.university.examcalc@0.1.0")
        XCTAssertEqual(
            capturedURL?.absoluteString,
            "https://registry.example.com/ontologies/edu.university.examcalc/0.1.0"
        )
        XCTAssertNotNil(capturedBody)
    }

    private func request(
        governanceDecisionPath: OntologySourcePath? = OntologySourcePath(
            path: "SPECS/ontology/examples/governance/approved-decision.yaml"
        ),
        goldenReportPath: OntologySourcePath? = nil
    ) throws -> OntologyCompiler.RegistryPublishRequest {
        OntologyCompiler.RegistryPublishRequest(
            path: OntologySourcePath(url: repoRoot.appendingPathComponent(
                "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"
            )),
            registry: try XCTUnwrap(RegistryBaseURL(string: "https://registry.example.com")),
            token: nil,
            channel: .trusted,
            governanceDecisionPath: governanceDecisionPath,
            goldenReportPath: goldenReportPath
        )
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func makeTemporaryDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
