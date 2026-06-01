import OntologyRules
import XCTest

final class ReferenceSpecsTests: XCTestCase {
    func testConceptRefResolutionSpecs() {
        let context = ConceptRefResolutionContext(
            ref: "foundation:Policy",
            localNames: ["Exam", "ExamPolicyProfile"],
            packageNamespace: "examcalc",
            importNamespaces: ["foundation"]
        )

        XCTAssertTrue(ImportedConceptRefSpec().isSatisfiedBy(context))
        XCTAssertTrue(ResolvableConceptRefSpec().isSatisfiedBy(context))

        let local = ConceptRefResolutionContext(
            ref: "Exam",
            localNames: ["Exam"],
            packageNamespace: "examcalc",
            importNamespaces: ["foundation"]
        )
        XCTAssertTrue(LocalConceptRefSpec().isSatisfiedBy(local))
        XCTAssertTrue(ResolvableConceptRefSpec().isSatisfiedBy(local))

        let unresolved = ConceptRefResolutionContext(
            ref: "Missing",
            localNames: ["Exam"],
            packageNamespace: "examcalc",
            importNamespaces: ["foundation"]
        )
        XCTAssertFalse(ResolvableConceptRefSpec().isSatisfiedBy(unresolved))
    }

    func testLocalTriggerRefSpec() {
        XCTAssertTrue(LocalTriggerRefSpec().isSatisfiedBy(
            TriggerRefResolutionContext(
                ref: "StartExamModeCommand",
                names: ["StartExamModeCommand"],
                packageNamespace: "examcalc"
            )
        ))

        XCTAssertTrue(LocalTriggerRefSpec().isSatisfiedBy(
            TriggerRefResolutionContext(
                ref: "examcalc:StartExamModeCommand",
                names: ["StartExamModeCommand"],
                packageNamespace: "examcalc"
            )
        ))

        XCTAssertFalse(LocalTriggerRefSpec().isSatisfiedBy(
            TriggerRefResolutionContext(
                ref: "foundation:StartExamModeCommand",
                names: ["StartExamModeCommand"],
                packageNamespace: "examcalc"
            )
        ))
    }
}
