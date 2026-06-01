import Foundation
@testable import OntologyCompiler
import OntologyRules
import XCTest
import Yams

final class CompetencyQuestionTests: XCTestCase {
    private typealias JSONMap = [String: Any]

    private struct CompetencyQuestion {
        let id: String
        let references: [String]
    }

    func testExamcalcCompetencyQuestionReferencesResolveOrEmitOntologyGap() throws {
        let questions = try loadCompetencyQuestions()
        let compiler = OntologyCompiler()
        let ir = try compiler.loadJSON(
            path: repoRoot
                .appendingPathComponent("SPECS/ontology/packages/examcalc/generated/ontology.normalized.json")
                .path
        )
        let conceptIndex = compiler.conceptRefIndex(ir)
        let resolver = OntologyReferenceSetResolutionSpec()
        var decisionsByQuestion = [String: OntologyReferenceSetResolution]()

        for question in questions {
            decisionsByQuestion[question.id] = try XCTUnwrap(resolver.decide(
                OntologyReferenceSetResolutionContext(
                    references: question.references,
                    conceptIndex: conceptIndex
                )
            ))
        }

        for question in questions where question.id != "CQ-005" {
            let decision = try XCTUnwrap(decisionsByQuestion[question.id])
            XCTAssertTrue(decision.allResolved, "\(question.id) should resolve all references")
            XCTAssertEqual(
                Set(decision.resolved),
                Set(question.references),
                "\(question.id) resolved reference set drifted"
            )
        }

        XCTAssertEqual(decisionsByQuestion["CQ-005"]?.gaps, ["examcalc:CASFunction"])
        let gap = compiler.ontologyGap(
            for: OntologyCompiler.RefOccurrence(
                ref: "examcalc:CASFunction",
                artifactKind: "CompetencyQuestion",
                artifactId: "CQ-005"
            ),
            ir: ir,
            ordinal: 1
        )

        let spec = try XCTUnwrap(gap["spec"] as? JSONMap)
        let sourceArtifact = try XCTUnwrap(spec["sourceArtifact"] as? JSONMap)
        XCTAssertEqual(gap["kind"] as? String, "OntologyGap")
        XCTAssertEqual((gap["metadata"] as? JSONMap)?["id"] as? String, "gap-001")
        XCTAssertEqual(sourceArtifact["kind"] as? String, "CompetencyQuestion")
        XCTAssertEqual(sourceArtifact["id"] as? String, "CQ-005")
        XCTAssertEqual(spec["missingConcept"] as? String, "examcalc:CASFunction")
        XCTAssertEqual((spec["requestedAction"] as? JSONMap)?["type"] as? String, "proposeOntologyDelta")
    }

    private func loadCompetencyQuestions() throws -> [CompetencyQuestion] {
        let url = repoRoot.appendingPathComponent("SPECS/ontology/examples/examcalc.competency-questions.yaml")
        let yaml = try String(contentsOf: url, encoding: .utf8)
        let document = try XCTUnwrap(try Yams.load(yaml: yaml) as? JSONMap)
        let spec = try XCTUnwrap(document["spec"] as? JSONMap)
        let rawQuestions = try XCTUnwrap(spec["questions"] as? [Any])

        return try rawQuestions.map { rawQuestion in
            let question = try XCTUnwrap(rawQuestion as? JSONMap)
            let id = try XCTUnwrap(question["id"] as? String)
            let exercises = try XCTUnwrap(question["exercises"] as? JSONMap)
            let references = ["concepts", "relations", "policies"]
                .flatMap { exercises[$0] as? [String] ?? [] }

            XCTAssertFalse(references.isEmpty, "\(id) must exercise at least one ontology reference")
            return CompetencyQuestion(id: id, references: references)
        }
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
