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

    func testClassFieldChangeDecisions() {
        let spec = CompatibilityChangeDecisionSpec()

        XCTAssertEqual(
            spec.decide(CompatibilityChangeContext(kind: .classRequiredFieldAdded, namespace: "examcalc", symbolId: "Exam.title")),
            .breaking("add required field examcalc:Exam.title")
        )
        XCTAssertEqual(
            spec.decide(CompatibilityChangeContext(kind: .classFieldRemoved, namespace: "examcalc", symbolId: "Exam.title")),
            .breaking("remove field examcalc:Exam.title")
        )
        XCTAssertEqual(
            spec.decide(CompatibilityChangeContext(
                kind: .classFieldTypeChanged,
                namespace: "examcalc",
                symbolId: "Exam.durationMinutes",
                beforeComparable: "integer",
                afterComparable: "number"
            )),
            .breaking("change field type examcalc:Exam.durationMinutes")
        )
        XCTAssertEqual(
            spec.decide(CompatibilityChangeContext(
                kind: .classFieldRequirednessChanged,
                namespace: "examcalc",
                symbolId: "Exam.title",
                beforeComparable: "false",
                afterComparable: "true"
            )),
            .breaking("make field required examcalc:Exam.title")
        )
        XCTAssertEqual(
            spec.decide(CompatibilityChangeContext(
                kind: .classFieldRequirednessChanged,
                namespace: "examcalc",
                symbolId: "Exam.title",
                beforeComparable: "true",
                afterComparable: "false"
            )),
            .compatible
        )
    }
}
