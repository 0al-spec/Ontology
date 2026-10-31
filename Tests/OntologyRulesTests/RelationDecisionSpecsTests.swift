import OntologyRules
import XCTest

final class RelationDecisionSpecsTests: XCTestCase {
    func testSourceShapePreservesMalformedSlotsForDiagnostics() {
        let spec = RelationRangeShapeDecisionSpec()
        let mixed: [String: Any] = ["oneOf": [42, "sg:Typo", false, "Exam"] as [Any]]
        XCTAssertEqual(spec.sourceShape(of: mixed), .oneOfMembers([nil, "sg:Typo", nil, "Exam"]))
        XCTAssertEqual(spec.decide(mixed), .oneOfRefs(["sg:Typo", "Exam"]))
        XCTAssertEqual(spec.sourceShape(of: ["oneOf": [] as [Any]]), .oneOfMembers([]))
        XCTAssertEqual(spec.sourceShape(of: ["oneOf": "Exam"]), .invalid)
    }

    func testRelationRangeShapeDecisionSpec() {
        let spec = RelationRangeShapeDecisionSpec()

        XCTAssertEqual(spec.decide("Exam"), .scalarRef("Exam"))
        XCTAssertEqual(spec.decide(["oneOf": ["Exam", "FunctionSet"]]), .oneOfRefs(["Exam", "FunctionSet"]))
        XCTAssertEqual(spec.decide(["oneOf": ["Exam", 42]]), .oneOfRefs(["Exam"]))
        XCTAssertEqual(spec.decide(["anyOf": ["Exam"]]), .invalid)
    }
}
