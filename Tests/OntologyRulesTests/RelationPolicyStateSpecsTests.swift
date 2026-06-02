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

        XCTAssertTrue(spec.isSatisfiedBy(PolicyEnforceability(rawValue: "design")))
        XCTAssertTrue(spec.isSatisfiedBy(PolicyEnforceability(rawValue: "runtime")))
        XCTAssertTrue(spec.isSatisfiedBy(PolicyEnforceability(rawValue: "manual")))
        XCTAssertTrue(spec.isSatisfiedBy(PolicyEnforceability(rawValue: "audit")))
        XCTAssertFalse(spec.isSatisfiedBy(PolicyEnforceability(rawValue: "optional")))
    }

    func testDeclaredStateSpec() {
        let spec = DeclaredStateSpec()

        let typedContext = StateMembershipContext(
            stateName: OntologyStateName(rawValue: "active"),
            declaredStates: [
                OntologyStateName(rawValue: "active"),
                OntologyStateName(rawValue: "ended")
            ]
        )
        XCTAssertEqual(typedContext.state, "active")
        XCTAssertEqual(typedContext.states, ["active", "ended"])

        XCTAssertTrue(spec.isSatisfiedBy(StateMembershipContext(state: "active", states: ["active", "ended"])))
        XCTAssertFalse(spec.isSatisfiedBy(StateMembershipContext(state: "missing", states: ["active", "ended"])))
    }
}
