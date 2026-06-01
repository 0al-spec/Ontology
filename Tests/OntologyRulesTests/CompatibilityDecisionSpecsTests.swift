import OntologyRules
import XCTest

final class CompatibilityDecisionSpecsTests: XCTestCase {
    func testRemovalDecisionsProduceExistingBreakingMessages() {
        let spec = CompatibilityChangeDecisionSpec()

        XCTAssertEqual(
            spec.decide(CompatibilityChangeContext(kind: .removedClass, namespace: "examcalc", symbolId: "Exam")),
            .breaking("remove class examcalc:Exam")
        )
        XCTAssertEqual(
            spec.decide(CompatibilityChangeContext(kind: .removedRelation, namespace: "examcalc", symbolId: "allows")),
            .breaking("remove relation examcalc:allows")
        )
    }

    func testRelationFieldChangeDecisions() {
        let spec = CompatibilityChangeDecisionSpec()

        XCTAssertEqual(
            spec.decide(CompatibilityChangeContext(
                kind: .relationDomainChanged,
                namespace: "examcalc",
                symbolId: "allows",
                beforeComparable: "Exam",
                afterComparable: "Policy"
            )),
            .breaking("change relation domain examcalc:allows")
        )
        XCTAssertEqual(
            spec.decide(CompatibilityChangeContext(
                kind: .relationRangeChanged,
                namespace: "examcalc",
                symbolId: "allows",
                beforeComparable: "FunctionSet",
                afterComparable: "FunctionSet"
            )),
            .compatible
        )
    }
}
