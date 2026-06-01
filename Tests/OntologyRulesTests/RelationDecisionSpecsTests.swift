import OntologyRules
import XCTest

final class RelationDecisionSpecsTests: XCTestCase {
    func testRelationRangeShapeDecisionSpec() {
        let spec = RelationRangeShapeDecisionSpec()

        XCTAssertEqual(spec.decide("Exam"), .scalarRef("Exam"))
        XCTAssertEqual(spec.decide(["oneOf": ["Exam", "FunctionSet"]]), .oneOfRefs(["Exam", "FunctionSet"]))
        XCTAssertEqual(spec.decide(["oneOf": ["Exam", 42]]), .oneOfRefs(["Exam"]))
        XCTAssertEqual(spec.decide(["anyOf": ["Exam"]]), .invalid)
    }
}
