import OntologyRules
import XCTest

final class RelationPolicyStateSpecsTests: XCTestCase {
    func testRelationRangeShapeSpecs() {
        XCTAssertTrue(ScalarRelationRangeSpec().isSatisfiedBy("Exam"))
        XCTAssertFalse(ScalarRelationRangeSpec().isSatisfiedBy(["oneOf": ["Exam"]]))

        XCTAssertTrue(OneOfRelationRangeSpec().isSatisfiedBy(["oneOf": ["Exam", "FunctionSet"]]))
        XCTAssertFalse(OneOfRelationRangeSpec().isSatisfiedBy(["anyOf": ["Exam"]]))
    }

    func testPolicyEnforceabilitySpec() {
        let spec = AllowedPolicyEnforceabilitySpec()

        XCTAssertTrue(spec.isSatisfiedBy("design"))
        XCTAssertTrue(spec.isSatisfiedBy("runtime"))
        XCTAssertTrue(spec.isSatisfiedBy("manual"))
        XCTAssertTrue(spec.isSatisfiedBy("audit"))
        XCTAssertFalse(spec.isSatisfiedBy("optional"))
    }

    func testDeclaredStateSpec() {
        let spec = DeclaredStateSpec()

        XCTAssertTrue(spec.isSatisfiedBy(StateMembershipContext(state: "active", states: ["active", "ended"])))
        XCTAssertFalse(spec.isSatisfiedBy(StateMembershipContext(state: "missing", states: ["active", "ended"])))
    }
}
