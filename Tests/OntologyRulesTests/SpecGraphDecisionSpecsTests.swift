import OntologyRules
import XCTest

final class SpecGraphDecisionSpecsTests: XCTestCase {
    func testSpecGraphRefDecisionSpec() {
        let spec = SpecGraphRefDecisionSpec()
        let concept: OntologyJSONObject = [
            "alias": "examcalc:Exam",
            "concept": "Exam"
        ]

        switch spec.decide(SpecGraphRefDecisionContext(ref: "examcalc:Exam", conceptIndex: ["examcalc:Exam": concept])) {
        case .resolved(let resolved):
            XCTAssertEqual(resolved["alias"] as? String, "examcalc:Exam")
        default:
            XCTFail("Expected resolved decision")
        }

        switch spec.decide(SpecGraphRefDecisionContext(ref: "examcalc:Missing", conceptIndex: ["examcalc:Exam": concept])) {
        case .gap:
            break
        default:
            XCTFail("Expected gap decision")
        }
    }

    func testOntologyReferenceSetResolutionSpec() throws {
        let spec = OntologyReferenceSetResolutionSpec()
        let concept: OntologyJSONObject = [
            "alias": "examcalc:Exam",
            "concept": "Exam"
        ]

        let decision = try XCTUnwrap(spec.decide(OntologyReferenceSetResolutionContext(
            references: ["examcalc:Exam", "examcalc:Missing"],
            conceptIndex: ["examcalc:Exam": concept]
        )))

        XCTAssertEqual(decision.resolved, ["examcalc:Exam"])
        XCTAssertEqual(decision.gaps, ["examcalc:Missing"])
        XCTAssertFalse(decision.allResolved)
    }
}
