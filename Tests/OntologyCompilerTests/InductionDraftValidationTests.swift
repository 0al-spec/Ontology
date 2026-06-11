import Foundation
import OntologyCompiler
import XCTest
import Yams

final class InductionDraftValidationTests: XCTestCase {
    func testValidateInductionDraftPassesValidFixtureAndWritesReport() throws {
        let report = try makeTemporaryDirectory(name: "induction-draft-pass")
            .appendingPathComponent("report.yaml")

        let result = try OntologyCompiler().validateInductionDraft(
            directory: OntologySourcePath(path: fixture("valid/voice-recorder")),
            outPath: OntologyOutputPath(path: report.path)
        )

        XCTAssertTrue(result.passed, String(describing: result.diagnostics))
        let reportObject = try XCTUnwrap(Yams.load(yaml: try String(contentsOf: report)) as? [String: Any])
        XCTAssertEqual(reportObject["kind"] as? String, "InductionDraftValidationReport")
        let trustBoundary = try XCTUnwrap(reportObject["trustBoundary"] as? [String: Any])
        XCTAssertEqual(trustBoundary["status"] as? String, "candidate_only")
    }

    func testValidateInductionDraftRejectsInvalidFixturesWithStableDiagnostics() throws {
        let cases = [
            ("invalid/missing-provenance", "inductionDraft.provenance.required"),
            ("invalid/missing-uncertainties", "inductionDraft.uncertainties.required"),
            ("invalid/unsupported-api-version", "inductionDraft.apiVersion.invalid"),
            ("invalid/non-draft-package-status", "inductionDraft.package.approvalStatus.invalid")
        ]

        for (fixturePath, expectedCode) in cases {
            let result = try OntologyCompiler().validateInductionDraft(
                directory: OntologySourcePath(path: fixture(fixturePath)),
                outPath: nil
            )

            XCTAssertFalse(result.passed, fixturePath)
            XCTAssertTrue(
                result.diagnostics.contains { $0.code == expectedCode },
                "\(fixturePath) did not emit \(expectedCode): \(result.diagnostics)"
            )
        }
    }

    private func fixture(_ path: String) -> String {
        repoRoot
            .appendingPathComponent("SPECS/ontology/fixtures/induction-drafts")
            .appendingPathComponent(path)
            .path
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
