import Foundation
import OntologyCompiler
import XCTest
import Yams

final class GoldenIntentValidationTests: XCTestCase {
    func testGoldenIntentValidationPassesMatchingCandidate() throws {
        let directory = try makeTemporaryDirectory(name: "golden-intent-pass")
        let expectation = try write(goldenExpectation, to: directory.appendingPathComponent("expectation.yaml"))
        let candidate = try write(passingCandidate, to: directory.appendingPathComponent("candidate.yaml"))
        let report = directory.appendingPathComponent("report.yaml")

        let result = try OntologyCompiler().validateGoldenIntent(
            expectationPath: OntologySourcePath(path: expectation.path),
            candidatePath: OntologySourcePath(path: candidate.path),
            outPath: OntologyOutputPath(path: report.path)
        )

        XCTAssertTrue(result.passed)
        let reportObject = try XCTUnwrap(Yams.load(yaml: try String(contentsOf: report)) as? [String: Any])
        XCTAssertEqual(reportObject["kind"] as? String, "GoldenIntentValidationReport")
        let resultObject = try XCTUnwrap(reportObject["result"] as? [String: Any])
        XCTAssertEqual(resultObject["passed"] as? Bool, true)
        XCTAssertTrue(try String(contentsOf: report).contains("manual_review_required"))
    }

    func testGoldenIntentValidationFailsMissingPolicyAndForbiddenConcept() throws {
        let directory = try makeTemporaryDirectory(name: "golden-intent-fail")
        let expectation = try write(goldenExpectation, to: directory.appendingPathComponent("expectation.yaml"))
        let candidate = try write(failingCandidate, to: directory.appendingPathComponent("candidate.yaml"))

        let result = try OntologyCompiler().validateGoldenIntent(
            expectationPath: OntologySourcePath(path: expectation.path),
            candidatePath: OntologySourcePath(path: candidate.path),
            outPath: nil
        )

        XCTAssertFalse(result.passed)
        let checks = try XCTUnwrap(result.report["checks"] as? [[String: Any]])
        XCTAssertTrue(checks.contains { $0["id"] as? String == "DenyByDefaultPolicy" && $0["status"] as? String == "fail" })
        XCTAssertTrue(checks.contains { $0["id"] as? String == "CalculatorButton" && $0["status"] as? String == "fail" })
    }

    func testGoldenIntentValidationRejectsMalformedExpectationShape() throws {
        let directory = try makeTemporaryDirectory(name: "golden-intent-malformed")
        let expectation = try write(
            goldenExpectation.replacingOccurrences(
                of: """
                  domainEntities:
                    - Exam
                    - ExamPolicyProfile
                    - ExamModeSession
                    - AuditLogEntry
                """,
                with: "  domainEntities: Exam"
            ),
            to: directory.appendingPathComponent("expectation.yaml")
        )
        let candidate = try write(passingCandidate, to: directory.appendingPathComponent("candidate.yaml"))

        XCTAssertThrowsError(try OntologyCompiler().validateGoldenIntent(
            expectationPath: OntologySourcePath(path: expectation.path),
            candidatePath: OntologySourcePath(path: candidate.path),
            outPath: nil
        )) { error in
            XCTAssertTrue(String(describing: error).contains("goldenIntent.minimumConcepts.type"), String(describing: error))
        }
    }

    func testGoldenIntentValidationRejectsUnknownExpectationApiVersion() throws {
        let directory = try makeTemporaryDirectory(name: "golden-intent-api-version")
        let expectation = try write(
            goldenExpectation.replacingOccurrences(
                of: "apiVersion: ontology-induction.specgraph.io/v1alpha1",
                with: "apiVersion: ontology-induction.specgraph.io/v9"
            ),
            to: directory.appendingPathComponent("expectation.yaml")
        )
        let candidate = try write(passingCandidate, to: directory.appendingPathComponent("candidate.yaml"))

        XCTAssertThrowsError(try OntologyCompiler().validateGoldenIntent(
            expectationPath: OntologySourcePath(path: expectation.path),
            candidatePath: OntologySourcePath(path: candidate.path),
            outPath: nil
        )) { error in
            XCTAssertTrue(String(describing: error).contains("goldenIntent.apiVersion.invalid"), String(describing: error))
        }
    }

    private func makeTemporaryDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(_ text: String, to url: URL) throws -> URL {
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

private let goldenExpectation = """
kind: GoldenIntentSemanticExpectation
apiVersion: ontology-induction.specgraph.io/v1alpha1
metadata:
  id: test-exam
  sourceIntent: SPECS/ontology/golden-intents/exam-controlled-calculator.intent.md
  expectationType: minimum-semantic-criteria
domainFrame:
  surfaceProduct: CalculatorApplication
  deepDomain: ExamControlledComputation
governingConcept:
  id: ExamPolicyProfile
  mustBeCentral: true
minimumConcepts:
  domainEntities:
    - Exam
    - ExamPolicyProfile
    - ExamModeSession
    - AuditLogEntry
  capabilities:
    - CalculatorFunction
  events:
    - PolicyViolation
minimumRelations:
  - id: records
    domain: AuditLogEntry
    range: PolicyViolation
policyExpectations:
  mustInclude:
    - DenyByDefaultPolicy
  enforceability:
    runtime:
      - DenyByDefaultPolicy
lifecycleExpectations:
  stateMachines:
    - id: ExamModeSessionState
      appliesTo: ExamModeSession
      mustIncludeStates:
        - initialized
        - active
forbiddenCoreConcepts:
  - id: CalculatorButton
    reason: UI control, not domain ontology core.
competencyQuestions:
  mustCover:
    - allowed functions for a given exam
"""

private let passingCandidate = """
apiVersion: ontology.specgraph.io/v1alpha1
kind: DomainOntologyPackage
metadata:
  id: test.exam
  namespace: testexam
  version: 0.1.0
spec:
  imports:
    - id: specgraph.foundation
      namespace: sg
      version: 0.1.0
  classes:
    Exam:
      extends: sg:DomainEntity
      description: Exam.
    ExamPolicyProfile:
      extends: sg:DomainEntity
      description: Policy.
      central: true
    ExamModeSession:
      extends: sg:DomainEntity
      lifecycle: ExamModeSessionState
      description: Session.
    AuditLogEntry:
      extends: sg:DomainEntity
      description: Audit entry.
    CalculatorFunction:
      extends: sg:Capability
      description: Function.
    PolicyViolation:
      extends: sg:Event
      description: Violation.
  protocols: {}
  relations:
    records:
      domain: AuditLogEntry
      range:
        oneOf:
          - PolicyViolation
          - ExamModeSession
  policies:
    DenyByDefaultPolicy:
      extends: sg:Policy
      enforceability: runtime
      appliesTo:
        - ExamPolicyProfile
      text: Deny by default.
  stateMachines:
    ExamModeSessionState:
      states:
        - initialized
        - active
      transitions:
        - from: initialized
          to: active
"""

private let failingCandidate = """
apiVersion: ontology.specgraph.io/v1alpha1
kind: DomainOntologyPackage
metadata:
  id: test.exam
  namespace: testexam
  version: 0.1.0
spec:
  imports:
    - id: specgraph.foundation
      namespace: sg
      version: 0.1.0
  classes:
    Exam:
      extends: sg:DomainEntity
      description: Exam.
    ExamPolicyProfile:
      extends: sg:DomainEntity
      description: Policy.
      central: true
    ExamModeSession:
      extends: sg:DomainEntity
      lifecycle: ExamModeSessionState
      description: Session.
    AuditLogEntry:
      extends: sg:DomainEntity
      description: Audit entry.
    CalculatorFunction:
      extends: sg:Capability
      description: Function.
    PolicyViolation:
      extends: sg:Event
      description: Violation.
    CalculatorButton:
      extends: sg:DomainEntity
      description: UI button.
  protocols: {}
  relations:
    records:
      domain: AuditLogEntry
      range: PolicyViolation
  policies:
    AllowByDefaultPolicy:
      extends: sg:Policy
      enforceability: runtime
      appliesTo:
        - ExamPolicyProfile
      text: Wrong policy for expectation.
  stateMachines:
    ExamModeSessionState:
      states:
        - initialized
        - active
      transitions:
        - from: initialized
          to: active
"""
