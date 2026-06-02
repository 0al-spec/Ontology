import OntologyRules
import XCTest

final class ReferenceSpecsTests: XCTestCase {
    func testConceptRefResolutionContextStoresTypedInputs() {
        let context = ConceptRefResolutionContext(
            reference: OntologyConceptReferenceLiteral(rawValue: "foundation:Policy"),
            localSymbols: [OntologySymbolName(rawValue: "Exam")],
            namespace: OntologyNamespace(rawValue: "examcalc"),
            importedNamespaces: [OntologyNamespace(rawValue: "foundation")]
        )

        XCTAssertEqual(context.ref, "foundation:Policy")
        XCTAssertEqual(context.localNames, ["Exam"])
        XCTAssertEqual(context.packageNamespace, "examcalc")
        XCTAssertEqual(context.importNamespaces, ["foundation"])
    }

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

    func testTriggerRefResolutionContextStoresTypedInputs() {
        let context = TriggerRefResolutionContext(
            reference: OntologyConceptReferenceLiteral(rawValue: "StartExamModeCommand"),
            localSymbols: [OntologySymbolName(rawValue: "StartExamModeCommand")],
            namespace: OntologyNamespace(rawValue: "examcalc")
        )

        XCTAssertEqual(context.ref, "StartExamModeCommand")
        XCTAssertEqual(context.names, ["StartExamModeCommand"])
        XCTAssertEqual(context.packageNamespace, "examcalc")
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
