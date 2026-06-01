import OntologyRules
import XCTest

final class ReferenceDecisionSpecsTests: XCTestCase {
    func testConceptRefResolutionDecisionSpec() {
        let spec = ConceptRefResolutionDecisionSpec()

        XCTAssertEqual(spec.decide(ConceptRefResolutionContext(
            ref: "Exam",
            localNames: ["Exam"],
            packageNamespace: "examcalc",
            importNamespaces: ["foundation"]
        )), .local)

        XCTAssertEqual(spec.decide(ConceptRefResolutionContext(
            ref: "foundation:Policy",
            localNames: ["Exam"],
            packageNamespace: "examcalc",
            importNamespaces: ["foundation"]
        )), .imported)

        XCTAssertEqual(spec.decide(ConceptRefResolutionContext(
            ref: "Missing",
            localNames: ["Exam"],
            packageNamespace: "examcalc",
            importNamespaces: ["foundation"]
        )), .unresolved)

        XCTAssertEqual(spec.decide(ConceptRefResolutionContext(
            ref: "bad-ref",
            localNames: ["Exam"],
            packageNamespace: "examcalc",
            importNamespaces: ["foundation"]
        )), .invalidSyntax)
    }

    func testConceptRefResolutionDecisionResolvesFlag() {
        XCTAssertTrue(ConceptRefResolutionDecision.local.resolves)
        XCTAssertTrue(ConceptRefResolutionDecision.imported.resolves)
        XCTAssertFalse(ConceptRefResolutionDecision.unresolved.resolves)
        XCTAssertFalse(ConceptRefResolutionDecision.invalidSyntax.resolves)
    }
}
